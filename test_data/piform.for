c----------------------------------------------------------------------------
c
c     P I F O R M - Program to produce near-publishable form of output from
c                   SPFIT
c
c                   This is an automatic version of PIFORM that is able to work
C                   out input and output on the basis of the fitting data file
c                   entry in the SVIEW_L input file (but explicit input and
c                   output declaration is still possible)
c
c----------------------------------------------------------------------------
c
c     PIFORM works on the .FIT file                                     = unit 2
c            and writes output to a .RES file                           = unit 3
c
c            if available then the .LIN file                            = unit 4
c            and the .PAR file                                          = unit 7
c            are also read.
c
c            The generic names of all files are derived from that of the .FIT file,
c            and that name may either be input manually or is the fitting file
c            name declared in the SVIEW_L file of the AABS package      = unit 8
c
c
c     The program will:
C
c     - reformat transition lines
c
c     - reformat the fitted parameters into values with errors in brackets and
c       convert errors on parameters to standard (67%) errors
c
c     - print advice concerning the worst fitted lines and poorest
c       parameter of fit
c
c     - produce a palatable correlation coefficient matrix
c
c     - transfer annotations from the .LIN file to the output. Such
c       annotations can be added at the ends of transition lines and
c       should begin with the character ''!' or '#'
c         i.   the character '!' generates a separate annotation preceding
C              the line containing this character.  The annotation line will
c              contain any text that has been placed behind  !, until
c              another ! or # is encountered in this line,
c         ii.  each additional ! character encountered after a given transition
c              definition will generate a new annotation line - so that
c              multiline blocks of annotations can be generated,
c         iii. the character '#' places the text that follows behind it
c              at the end of the current line of output.  Leading spaces
c              in the annotation are ignored.  Note that the # annotation
c              should follow any ! annotations, if those are used on the same line.
c
c     - for the special case of four quantum numbers per energy level in a spinless
c       fit PIFORM will automatically produce a breakdown of data set statistics
c       according to the value of the fourth quantum number and MICROWAVE/INFRARED data
c
c     - various versions of data statistics are also possible for other
c       quantum number combinations
c
C       ver. 10.03.2026                           ----- Zbigniew KISIEL -----
C                          __________________________________________________
C                         | Institute of Physics, Polish Academy of Sciences |
C                         | Al.Lotnikow 32/46, Warszawa, POLAND              |
C                         |                             kisiel@ifpan.edu.pl  |
C                         |     http://info.ifpan.edu.pl/~kisiel/prospe.htm  |
C_________________________/--------------------------------------------------
C
c
c   MODIFICATION HISTORY:
c
c         1994: Creation
c   12.06.1997: Compatibility with APR/97 version of SPFIT
c   29.11.1997: Correlation matrix
c   10.01.1998: Debugging
c   17.03.1998: Standard errors
c   17.05.1998: Reformat and copy to output all lines used in fit
c   17.08.1998: Debugging of fixed value
c   11.02.1999: Debugging of line output
c   26.03.1999: as above
c   24.10.1999: check against 1999 C-version of SPFIT + more debugging
c    5.11.1999: more of the above
c    3.12.1999: debugging of fixed parameter output
c   22.06.2000: modified output for lines not in fit
c   16.10.2001: debugging + check against March2001 version of SPFIT
c   17.09.2002: debugging, treatment of lines which are in fit but have
c               large DIFF or ERROR, transfer of annotations from the .LIN file
c   10.09.2003; # annotations
c    5.08.2005: Accounting for differences in output format for parameters
c               in more recent versions of SPFIT
c   30.09.2005: Treatment of dependent parameters in v1999+
c    2.01.2006: More than 99 parameters
c   16.01.2006: Treatment of large value with large error
c    4.02.2006: Modified reformatting and output of dependent parameters
c   10.04.2006: Debugging
c   23.07.2007: Dealing with FRAC different from unity
c    5.02.2009: Changes to processing of end of line comments
c    8.11.2009: Formatting of high order parameters for linear molecules
c   20.03.2010: Automated output based on SVIEW_L.INP
c    8.12.2010: last qn=0,1,2,3 statistics for four quantum numbers
c   16.02.2011: as above but with separate MICROWAVE and INFRARED blocks
c    9.04.2011: worst ten lines echoed in their entirety
c   10.06.2011: statistics also for v=4,5,6
c   28.10.2011: removing all i*2 and other debugging
C   25.11.2012: modifications and corrections to state statistics and rounding
C   27.03.2013: major revision of state-by-state statistics
c   10.01.2014: frequency/wavenumber state-by-state limits
c   14.05.2014: subset statistics for more than four quanta
c   15.01.2015: option of five and not four digit line numbers,
c               worst parameters and worst correlations
c   21.04.2015: vibrational binning for symmetric or asymmetric top quantisation
C   10.06.2015: compatibility with gfortran, single bin statistics + debugging
C   22.03.2016: clarification of statistics and negative FRAC warning
C   31.12.2016: debugging of operation with large errors
C    2.10.2017: cumulative improvements including better automatic binning based
C               on the .PAR file and more robust handling of rare parameter values
C   29.09.2018: debugging infrared bin statistics for split data blocks
C   27.12.2018: modified CONFOR from ASFIT (now parameter errors are also rounded)
C    5.08.2019: debugging treatment of .PAR continuation lines
c               (subversion b = allowance for smaller fixed values of >1.d-19)
c   10.05.2020: optional printout of transition type identifier
c   19.05.2020: removing obsolete Fortran constructs
c   30.07.2020: debugging parameter output for nvib>9
c   27.09.2020: MAXLIN increased to 100000
c   20.05.2022: elimination of a mixup for sextic and decadic default units
c   18.06.2025: print also number of .LIN lines
c   18.09.2025: debugging partial deviations
c   27.01.2026: rectifying missing e>=900 diagnostics for single state MW fit
c   10.03.2026: debugging infrared band labels after first fiot cycle
c
c----------------------------------------------------------------------------
C
C    Differences in output formats between different versions of SPFIT
C    are accounted for by variable NVERS, which currently can have
C    values:
C
C    2002 - this is characterised by a two character shift to the left
C           of the four rightmost columns of parameter block lines that took
C           place around 2002 (this is accounted for by MM=-2 set on the basis of
C           columns 19 and 20 being blank)
C    1999 - assigned on the basis of "." character in column 52 of a transition
C           line
C    1997
C    1995
C
C    The program is no longer tested against SPFIT versions older than the 
C    64-bit versions available on the PROSPE website at:
C           http://info.ifpan.edu.pl/~kisiel/asym/asym.htm#64bit
C
c----------------------------------------------------------------------------
C   Compilation
c----------------------------------------------------------------------------
c
c   Intel/Windows:   ifort -nopdbfile -nodebug -traceback -arch:IA32 -O3 -Qsave
c                    -ccdefault:fortran -fpscomp:filesfromcmd piform.for
c
c   not all these keywords are necessary but they constitute a generic set
c   for compiling PROSPE console programs to run on the broadest range of i86
c   processors
c
c
C   gfortran/Linux:  gfortran -fno-automatic piform.for -o piform
C
C
c----------------------------------------------------------------------------
c    Search for "c - -" to locate different processing blocks by searching for
c
c    MAXCON - maximum number of handled parameters
c    MAXLIN - maximum number of handled lines
c     CPERC - percentage error limit for identifying worst fitted parameters
c
      implicit real(8) (a-h,o-z)
      parameter (maxcon=6000,maxlin=100000,cperc=20.d0)
c
      character line*155,conval*27,erval*27
      character(30) filin,fillin,filout,filpar
      character cnames(maxcon)*10,unit*4,cident(maxcon)*10,linapp*80,
     *          pnames(maxcon)*10,crotor*10
      character now*10,last*10,ediagn*40
      character cdiff*8,cerr*7,cdiff1*8,cwork*40,cdummy*11
      integer infitc(0:maxcon),nsepl(maxcon)
      integer(4) concod,infpar(maxcon,2),transtyp
      integer(8) numpar(maxcon)
      real(8) constv(maxcon),ercons(maxcon),conmul(maxcon),wperc(maxcon)
      character linout(maxcon)*80,linbuf(maxlin)*130,linbufl*1000,
     *          worstcon(maxcon)*80,dipind*2,pqrind*2
      character lintest*200
      integer(8) idpar(maxcon)
      common /names/cnames,idpar,infitc
      COMMON /SORTCC/ominc(maxlin),IPT(maxlin)
      common /lbuff/linbuf
c
c...arrays for state by state breakdowns
c
c   IVV(i,j)- table mapping v_lower and v_upper values to the number of
c             successively identified vibrational transition where:
c             i is v for the lower state
c             j is v for the upper state
c             (NOTE: both i and j start at 0)
c
c    IVINDX - table mapping the number of successively identified vibrational
c             transition (from 1 to NVCOMB) to vibrational states where:
c             IVINDX(i,1) = v index of lower vibrational state
c             IVINDX(i,2) = v index of upper vibrational state
c
c    MAXVST - maximum number of different vibrational states
c     MAXVM - maximum number of different infrared transitions (this
c             includes both infrared pure rotational transitions and
c             vibrational transitions)
c
      PARAMETER (maxvst=51,maxv=maxvst-1,maxvm=150,maxqn=12)
      integer ivindx(0:maxvm,2),ivv(0:maxvm,0:maxvm),
     *        nqnup(maxqn),nqlow(maxqn),
     *        minlow(maxqn),maxlow(maxqn),minup(maxqn),maxup(maxqn)
c
c   MICROWAVE TRANSITIONS:
c
c   bin collection according to v" counted from 0 to MAXV (so that the
c   dimensionality limit is MAXVST=MAXV+1)
c
c         NFRE - number of fitted dv=0 lines
c        NFRED - number of fitted dv.ne.0 lines
c        NFREU - number of unfitted lines
c       NER900 - number of lines effectively excluded with large error
c         SDEV - standard deviation for the state
C        SWDEV - rms deviation for the state
c    MINJ,MAXJ - smallest and largest J for given v"
c    MINK,MAXK - smallest and largest Ka for given v"
c   FLOW,FHIGH - smallest and largest frequency
c
      integer nfre(0:maxvst),nfred(0:maxvst),nfreu(0:maxvst),
     *        ner900(0:maxvst),
     *        minj(0:maxvst),maxj(0:maxvst),
     *        mink(0:maxvst),maxk(0:maxvst)
      real(8) sdev(0:maxvst),swdev(0:maxvst),
     *        flow(0:maxvst),fhigh(0:maxvst)
c
c   INFRARED TRANSITIONS:
c
c   bin collection is according to v" and v' with their combinations
c   counted from 1 to MAXVM
c
c     NVCOMB - the actual number of different combinations in data
c     NVSTAT - the sequential number of vibrational state obtained from the
c              the lookup table IVV
c     NFREIR - number of fitted dv=0 lines
c    NFREIRD - number of fitted dv.ne.0 lines
c    NFREUIR - number of unfitted lines
c    NER09IR - number of lines effectively excluded with large (negative) error
c     SDEVIR - standard deviation for the state
C    SWDEVIR - rms deviation for the state
c    IRMINJ,IRMAXJ - smallest and largest J for given v"
c    IRMINK,IRMAXK - smallest and largest Ka for given v"
c   FLOWIR,FHIGHIR - smallest and largest wavenumber
c
      integer nfreir(0:maxvm),nfreird(0:maxvm),nfreuir(0:maxvm),
     *        ner09ir(0:maxvm),
     *        irminj(0:maxvm),irmaxj(0:maxvm),
     *        irmink(0:maxvm),irmaxk(0:maxvm)
      real(8) sdevir(0:maxvm),swdevir(0:maxvm),
     *        flowir(0:maxvm),fhighir(0:maxvm)
c
c
      character(40) outformat,format53,format1053,format1054,
     *                        format350,format1350,format1351
      format53=  '(a,2x,a,f12.4,1x,a,1x,a,f13.4,1x,a)'
      format1053='(a,2x,a,f12.5,1x,a,1x,a,f13.5,1x,a)'
      format1054='(a,2x,a,f12.3,1x,a,1x,a,f13.3,1x,a)'
      format350= '(a,2x,a,f12.4,1x,a,a,1x,a,f5.2,1x,a)'
      format1350='(a,2x,a,f12.5,1x,a,a,1x,a,f5.2,1x,a)'
      format1351='(a,2x,a,f12.3,1x,a,a,1x,a,f5.2,1x,a)'
c
      nvers=0
      nfitc=0
      lseen=0
      lshift=0
      lrejct=0
      ncolon=0
      transtyp=0

c
      WRITE(*,3344)
3344  FORMAT(1X//'  ',76('_')/' |',T79,'|'/
     * ' |   PIFORM  -  Reformatting of the .FIT output file from'
     * ,T79,'|'/
     * ' |              Pickett''s program SPFIT',
     * T79,'|'/' |',76('_'),'|'/
     * '  version 10.III.2026',T64,'Zbigniew KISIEL'//)
c
      write(*,7792)
7792  format(
     * ' - For trustworthy statistics make sure that only the ',
     *                                           'ERRTST mechanism'/
     * '   is used to exclude lines from the fit'//
     * ' - For best results ensure that .PAR and .LIN accompany',
     * ' the .FIT file,'/
     * '   but also ensure that in the .PAR file there is a comma ',
     * 'after SPIND'//
     * ' - Pressing ENTER as .FIT filename allows automated operation'/
     * '   based on the name found in SVIEW_L.INP'//)
c
c...Decide on type of input
c
1     write(*,2,advance='NO')
     * ' Name of input .FIT file (without extension):'
2     format(1x/1x,a,'  ')
      read(*,'(a)',err=1)filin
c
      nfilin=len_trim(filin)
      if(nfilin.eq.0)then
c
c...Set up input on the basis of SVIEW_L.INP
c
        iauto=1
        open(8,file='sview_l.inp',status='old',err=7773)
7777      read(8,'(a)',err=7776,end=7776)line
          if(line(1:1).eq.'!')goto 7777
          read(line(41:),*,err=7776,end=7776)filin
        close(8)
        write(*,'(1x//'' SVIEW_L.INP fitting file =  '',a)')
     *    filin(1:len_trim(filin))
        nfilin=len_trim(filin)
        filin=filin(1:nfilin)
        if(filin(nfilin-3:nfilin).eq.'.lin')then
          filin=filin(1:nfilin-4)
          n=len_trim(filin)
          filin= filin(1:n)//'.fit'
          fillin=filin(1:n)//'.lin'
          filpar=filin(1:n)//'.par'
        else
          goto 7771
        endif
c
      else
c
c...Set up input on the basis of the supplied generic file name
c
        iauto=0
        filin= filin(1:nfilin)//'.fit'
        fillin=filin(1:nfilin)//'.lin'
        filpar=filin(1:nfilin)//'.par'
c
      endif
c
c----------------------------------------------------------------------------
c   Open the .PAR file (if available):
c----------------------------------------------------------------------------
c   This allows checking:
c     1/ the number of lines in the fit
c     2/ establish linear/symmetric/asymmetric quantisation
c     3/ determine the total number of quantum numbers
c
c   CROTOR - comment field with rotor name
c   IROTOR - rotor identifier (0,1,2,3 for unkn,lin,sym,asym)
c   NSPINS - number of spin quantum numbers (0 if none)
c   NQNS   - number of quantum numbers
c
c   A delimited blank space in place of KNMIN and KNMAX leaves
c   the unusual initial values unchanged.
c   If there is no .PAR file then the various identifiers are left at their
c   unusual (undefined) initial values.
c
      crotor='UNKNOWN'
      irotor=0
      ispind=-555
      nspins=-555
      nvib=-555
      nqns=-555
      knmin=-555
      knmax=-555
      ibin=-555
c
      ninpar=0
      open(7,file=filpar,status='old',err=7708)
      ninpar=1
      read(7,'(a)',err=7710,end=7710)line                               ! first .PAR line
      ninpar=2
      read(7,*,err=7710,end=7710)nparcon,nparlin,                       ! second .PAR line
     *                           ndummy,ndummy,thresh,errtst
      ispind=0
      nspins=0
      nvib=0
      ninpar=3
c
c...Note that SPFIT accepts both integer and floating point values of
c   WTPL and WTMN (which should really be integers)
c
7719  read(7,'(a)',err=7710,end=7710)line
      read(line,*,err=7710,end=7710)                                    ! third .PAR line and its
     *                           cdummy(1:1),ispdum,nvibd,              ! possible continuations
     *                           knmin,knmax,
     *                           ixx,iax,iwtpl,iwtmn,ivsym
c
      if(ninpar.eq.3)nvib=nvibd
      if(iabs(ispdum).gt.iabs(ispind))ispind=ispdum
c     write(*,*)ninpar,ivsym,ispdum
c
c...if there is a continuation line then reset IVSYM back to zero, otherwise if
c   if it has been left as a space in the last continuation line then its last
c   read value (i.e. -1) is used
c
      if(ivsym.eq.-1)then
        ninpar=ninpar+1
        ivsym=0
        goto 7719
      endif
c
      if( (knmin.eq.knmax) .and. (knmin.eq.0))then
            crotor='LINEAR'
            irotor=1
      else
        if(ispind.lt.0)then
            crotor='SYMMETRIC'
            irotor=2
        else
            crotor='ASYMMETRIC'
            irotor=3
        endif
      endif
c
      ibin=0
      if(iabs(nvib).gt.1.and.irotor.eq.1)ibin=-2                        ! more than one v in linear rotor 
      if(iabs(nvib).gt.1.and.irotor.eq.2)ibin=-1                        ! more than one v in symm rotor 
      if(iabs(nvib).gt.1.and.irotor.eq.3)ibin=1                         ! more than one v in asymm rotor 
c
      nspins=0
      if(iabs(ispind).gt.1)nspins=1
      if(iabs(ispind).gt.10)nspins=2
      if(iabs(ispind).gt.100)nspins=3
      if(iabs(ispind).gt.1000)nspins=4
      if(iabs(ispind).gt.10000)nspins=5
c
      nmcolon=4
      if(nparlin.ge.10000)then
7712    write(*,7711,advance='NO')nparlin
7711    format(1x/
     * '  The fit file contains',i6,' lines so that please choose one'/
     * '  of these two options:'//
     * '     0 - use the default four digit line number output (no'/
     * '         leading 10000 digit): this preserves compatibility'/
     * '         with AC and ACIR'/
     * '     1 - print five digit line numbers for better readability,'/
     * '         but impaired compatibility with AC and ACIR'//
     * '   .....  ')
        read(*,'(i5)',err=7710)nn
        if(nn.lt.0.or.nn.gt.1)goto 7712
        if(nn.eq.1)nmcolon=5
      endif
c
      nvibqn=0
      if(iabs(nvib).gt.1)nvibqn=1
      nqns=irotor+nvibqn+nspins
      write(*,'(1x//'' -----> '',a,
     *     '' quantisation according to the .PAR file and:''/
     *         i12,'' vibrational state(s),''/
     *         i12,'' spin quantum number(s),''/
     *         i12,'' quantum number(s) per energy level.''/)')
     *         crotor(1:len_trim(crotor)),iabs(nvib),nspins,nqns
c
c...Deal with possible transition type identification, two conditions need to be met:
c     1/ request by negative input NERD
c     2/ confirmation by ASYMMETRIC quantisation with 3 or 4 quantum numbers per state
c
      if(irotor.eq.3.and.(nqns.eq.3.or.nqns.eq.4))then
        if(transtyp.ne.1)transtyp=0
      else
        transtyp=0
      endif
c
c
c...Deal with more than 6 quantum numbers (the only case encountered so
c   far is multiple spins, which are in that case reduced to nn,F, where
c   nn is the aggregate spin)
c
      if(nqns.gt.6)then
        write(*,'(8x,a/8x,a///8x,a)')
     *   'More than 6 quantum numbers, which are only',
     *   'displayed completely in the .EGY file',
     *   'Assuming that aggregate spins are used in .LIN and .CAT files'
     *
        nspins=2
        nqns=irotor+nvibqn+nspins
        write(*,'(1x/'' -----> '',a,'' quantisation and:''/
     *         i12,'' vibrational state(s),''/
     *         i12,'' spin quantum number(s),''/
     *         i12,'' quantum number(s) per energy level.''/)')
     *         crotor(1:len_trim(crotor)),iabs(nvib),nspins,nqns
      endif
c
      close(7)
      goto 7713
c
7710  write(*,'(1x/1x,''ERROR reading .PAR line'',i3,'':''/)')ninpar
      if(ninpar.gt.1)then
            backspace(7)
            read(7,'(a)')line
            write(*,'(1x,a/)')line(1:len_trim(line))
      endif
      close(7)
      stop
c
7708  close(7)
      write(*,'(1x/1x,''***** WARNING: Cannot open the .PAR file:''
     *         //1x,a/)')filpar(1:len_trim(filpar))
c
c----------------------------------------------------------------------------
c   Open the .FIT file
c----------------------------------------------------------------------------
c
7713  open(2,file=filin,status='old',err=7770)
c
c----------------------------------------------------------------------------
c   Open the .LIN file (if available):
c----------------------------------------------------------------------------
c   this file is optional and serves as the source of annotations on lines
c   transferred to the output file
c
      open(4,file=fillin,status='old',err=500)
      lnfile=1
      goto 7791
500   lnfile=0
c
c----------------------------------------------------------------------------
c   Open the output file
c----------------------------------------------------------------------------
c
7791  if(iauto.eq.1)then
        filout=filin(1:n)//'.res'
        write(*,'(''    Automatic output file =  '',a/)')
     *    filout(1:len_trim(filout))
        open(3,file=filout,status='unknown',err=7787)
        nerd=2
      else
3       write(*,2,advance='NO')'       Name of output file:'
        read(*,'(a)',err=3)filout
        open(3,file=filout,status='unknown',err=7787)
7       write(*,22,advance='NO')
     *  ' Number of error digits (-ve value invokes',
     *  '                         transition type identification):  '
22      format(1x/1x,a/1x,a)
        read(*,*,err=7)nerd
        if(nerd.lt.0)then
          transtyp=1
          nerd=-nerd
        endif
        if(nerd.lt.1.or.nerd.gt.6)then
          transtyp=0
          goto 7
        endif
      endif
c
c
      nworstc=0
      iflag=0
      nfreqs=0
      nlbuf=0
      nvcomb=0
c
      do 5015 nn=1,maxvm
        ivindx(nn,1)=0
        ivindx(nn,2)=0
        do 5016 nnn=1,maxvm
          ivv(nn,nnn)=0
5016    continue
5015  continue
c
      do 5020 nn=1,maxqn
        minup(nn) = 1000
        minlow(nn)= 1000
        maxlow(nn)=-1000
        maxup(nn) =-1000
5020  continue
c                                                                       ! MICROWAVE:
      do 5000 nn=0,maxv
        nfre(nn)=0                                                      ! fitted, dv=0
        nfred(nn)=0                                                     ! fitted, dv.ne.0
        nfreu(nn)=0                                                     ! unfitted
        ner900(nn)=0                                                    ! excluded with large error
        sdev(nn)=0.0d0                                                  ! deviation
        swdev(nn)=0.0d0                                                 ! rms deviation
        mink(nn)=500
        maxk(nn)=0
        minj(nn)=500
        maxj(nn)=0
        flow(nn)=1.d20
        fhigh(nn)=-1.d20
5000  continue
c                                                                       ! INFRARED:
      do 5001 nn=0,maxvm
        nfreir(nn)=0                                                    ! fitted, dv=0
        nfreird(nn)=0                                                   ! fitted, dv.ne.0
        nfreuir(nn)=0                                                   ! unfitted
        ner09ir(nn)=0                                                   ! excluded with large error
        sdevir(nn)=0.0d0                                                ! deviation
        swdevir(nn)=0.0d0                                               ! rms deviation
        irmink(nn)=500
        irmaxk(nn)=0
        irminj(nn)=500
        irmaxj(nn)=0
        flowir(nn)=1.d20
        fhighir(nn)=-1.d20
5001  continue
c
c
      nfitc=0
      flast=0.0d0
      iunfit=0
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   DEAL WITH THE HEADER LINES
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
c...comment line
c
      read(2,'(a)',end=5)line                                           ! INPUT of title
      write(3,351)line(1:54)//line(57:80)                               ! OUTPUT of title
351   format(a)
c
c...deal with non-unity FRAC, for which SPFIT14+ (July2007) can print an
c   additional line in this place:
c
cPARAMETER ERRORS SCALED BY        0.573110                             ! for FRAC=0.57311
cPARAMETER ERRORS SCALED BY        1.000000 times the standard error    ! for FRAC=-1
c
      read(2,'(a)',end=5)line                                           ! INPUT of optional FRAC line
      FRAC=1.d0
      if(line(1:26).eq.'PARAMETER ERRORS SCALED BY')then
        ediagn='PARAMETER ERROR scaling parameter FRAC'
        read(line(30:42),'(f13.6)',err=357,end=357)frac
        if(line(44:48).eq.'times')frac=-frac
        read(2,'(a)',end=5)line
      endif
c
c...read PARAMETER lines at the top of the .FIT file, which declare,
c   among others, linear dependencies between parameters
c
c    4      2   -1000000000 -4.1604802621495E+004       -0.021251 V3    <--- SPFIT16
c    5      2   -1000000011  2.0802401310752E+004        0.010626 V3
c
c   31     31     11001000000 -3.3412265800446E+000   1.000000E-037 Xaa <--- SPFIT16 nvib >= 10
c   32     31    -11003000000  3.3412265800446E+000       -1.000000 Xcc
c   33     32     11002000000  1.2925641162900E+000   1.000000E-037 Xbb
c   34     32    -11003000000 -1.2925641162900E+000       -1.000000 Xcc
c
c    1      1         10000  2.3730188823858E+003   1.000000E+005  A    <--- SPFIT12
c    2      1        -20000  2.3730188823858E+003        1.000000  B
c
c    1      1            10000  2.3730188778722E+003   1.000000E+005  A <--- SPFIT7
c    2      1           -20000  2.3730188778722E+003        1.000000  B
c
      read(2,'(a)',end=5)line                                           ! INPUT skip a line
      read(2,'(a)',end=5)line                                           ! INPUT skip a line
      npared=0
      nindep=0
      if(line(31:40).ne.'PARAMETERS')goto 4
c
c...Repeat of parameter declaration input from here
c
44    read(2,'(a)')line                                                 ! INPUT parameter declarations
c
      if(line(3:12).ne.'parameters'.and.                                ! sensing nvers=1999+
     *    line(4:13).ne.'parameters'.and.                               ! header termination
     *     line(5:14).ne.'parameters'.and.
     *       line(6:16).ne.'parameters')then
        npared=npared+1
c
c...free form input with a dummy variable ensuring WINDOWS/LINUX compatibility
c
c   Parameter multipliers for dependent parameters as printed are unreliable for
c   very small values, so work all multipliers out from the values of paramaters
c
c   A problem may arise for exact zero value of parameter (division by zero), and
c   in such case multiplier value of 1 is assumed
c
1360    read(line, *,err=358,end=1358)
     *                         (infpar(npared,n),n=1,2),numpar(npared),
     *                         rdummy,conmul(npared),pnames(npared)
        if(numpar(npared).ge.0)then
          conindep=rdummy
        else
          if(conindep.eq.0.0d0)then
            conmul(npared)=1.0d0
          else
            conmul(npared)=rdummy/conindep
          endif
        endif
        goto 1359
c
1358    line=line(1:len_trim(line))//' .'                               ! patch for missing
        goto 1360                                                       ! parameter alphanumeric
c
1359    if(pnames(npared)(1:2).eq.'-d'.or.                              ! deal with -ve descriptor
     *     pnames(npared)(1:2).eq.'-D')then
             pnames(npared)=pnames(npared)(2:)
        endif
        nn=len_trim(pnames(npared))
        pnames(npared)(11-nn:10)=pnames(npared)(1:nn)
        pnames(npared)(1:10-nn)='          '
        goto 44
      else
        do 60 n=1,len_trim(line)
          if(line(n:n).eq.'p')then
            read(line(1:n-1),*,err=358,end=358)npared                   ! read no of 'paramaters read'
            goto 61
          endif
60      continue
61      do 62 n=10,len_trim(line)
          if(line(n:n).eq.',')then
            nstart=n+1
            goto 63
          endif
62      continue
63      do 64 n=nstart,len_trim(line)
          if(line(n:n).eq.'p')then
            nend=n-1
            goto 65
          endif
64      continue
65      read(line(nstart:nend),*,err=358,end=358)nindep                 ! read no of independent paramaters
        goto 4444
      endif
c
c...establish from the .FIT file whether spins are involved
c
4444  read(2,'(a)',end=5)line
      if(line(5:15).ne.'V KMIN KMAX'.and.
     *   line(4:14).ne.'V KMIN KMAX')goto 4444
      read(2,'(a)',end=5)line
      if(len_trim(line).gt.37)then                                      ! this may be obsolete
        ispin=1
      else
        ispin=0
      endif
c
c
c////////////////////////////////////////////////////////////////////////////
c/// control returns here once the header has been processed ////////////////
c////////////////////////////////////////////////////////////////////////////
c
c   MAIN INPUT LOOP
c
c...Read a line of input and take appropriate action, control comes back
c   to statement 4 until EOF
c
4     read(2,'(a)',err=5,end=5)line                                     ! INPUT next .FIT line
c
c...echo the 'lines rejected' from the .fit file
c
      if(line(7:20).eq.'Lines rejected')then
        write(3,'(85(''-''),9(''='')/a)')line(1:29)                     ! OUTPUT no of lines rejected
        lrejct=1
        read(line(1:5),'(i5)',err=4)nrejl
        goto 4
      endif
c
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Transition not used in the fit
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
c   if a line has not been used in fit then reformat and use
c   the blend field to print the calculated value
c
      if(line(3:12).eq.'***** NEXT'.or.
     *   line(2:11).eq.'***** NEXT')then
        iunfit=1
        read(2,'(a)')line
c
c...write line block header if not yet done so and attempt to establish
c   the number of quantum numbers from the .FIT output
c   If a .PAR has already been read above then this is just a double check,
c   but if not then this is the only mechanism for invoking subset statistics
c
        if(lseen.eq.0)then
          lseen=1
          if(line(52:52).eq.'.'.or.line(50:50).eq.'.')then
            nvers=1999
            lshift=1
          endif
          write(3,355)                                                  ! OUTPUT line block header
          nqnsfit=6
          do 453 n=42+lshift,18+lshift,-6
            if(line(n:n).ne.' ')goto 454
            nqnsfit=nqnsfit-1
453       continue
454       nbreak=7+nqnsfit*3
c
          write(*,591)nqnsfit
591       format(1x//i12,' quantum number(s) per energy level ',
     *                              'according to the .FIT file'/)
c
c...IBIN=-555 at this stage is equivalent to not having been through the .PAR file
C
          if(ibin.eq.-555)then
            ibin=0
            nqns=nqnsfit
            if(nqns.eq.4.and.ispin.eq.0)then
              ibin=1
            else
              if(nqns.gt.4)then
592             write(*,593,advance='NO')
593             format(1x/
     *     ' Optional subset statistics according to the vibrational'/
     *     ' quantum number (of the lower state)'//
     *     '        -1 = for symmetric top type J,K quantisation'/
     *     '         0 = none'/
     *     '         1 = for asymmetric top J,Ka,Kc quantisation'//
     *     '    .... ')
                read(*,'(i5)',err=592)idummy
                if(iabs(idummy).eq.1)ibin=idummy
                write(*,'(1x)')
              endif
            endif                                                       ! nqns
          endif                                                         ! ibin
        endif                                                           ! lseen
c
        goto 56
      endif
c
c...check for a continuation line in an unfitted blend
c
      if(iunfit.eq.1)then
c
c___not a legal line
        if(line(6:6).ne.':'.and.
     *      (line(51:51).ne.'.'.and.line(52:52).ne.'.') )then
          iunfit=0
          goto 4
        endif
        ediagn='EXP.FREQ. on testing for unfitted blend'
        read(line(43+lshift:56+lshift),'(f14.5)',err=357)freq
c
c___not a component of the previous blend
        if(freq.ne.flast)then
          nfreqs=nfreqs+1
          flast=freq
          iunfit=0
          ioldbl=0
          goto 50
        endif
      endif
c
c...Output for transition not used in fit
c
56    if(iunfit.eq.1)then
        ediagn='EXP.FREQ. for line not in fit'
        read(line(43+lshift:56+lshift),'(f14.5)',err=357)freq
        ediagn='DIFF. for line not in fit'
c       read(line(71+lshift:80+lshift),'(f10.5)',err=357)diff
        read(line(71+lshift:81+lshift),'(f11.5)',err=357)diff
        if(line(90+2*lshift:90+2*lshift).ne.'*')then
          read(line(81+3*lshift:90+3*lshift),'(f10.5)',err=357)error
        else
          error=1.E10
        endif
        if(error.ge.0.0d0)then
          write(cdiff,'(f8.4)')diff
          if(diff.ge.10000.)write(cdiff,'(f8.2)')diff
          if(diff.ge.1000.)write(cdiff,'(f8.3)')diff
          if(diff.le.-1000.)write(cdiff,'(f8.2)')diff
          if(diff.le.-100.)write(cdiff,'(f8.3)')diff
          if(cdiff(3:3).eq.' ')cdiff(3:3)='0'
          if(cdiff(3:3).eq.'-')then
            cdiff(2:2)='-'
            cdiff(3:3)='0'
          endif
        else
          write(cdiff,'(f8.5)')diff
        endif
c
        ediagn='CALC.FREQ. for line not in fit'
        read(line(57+lshift:70+lshift),'(f14.5)',err=357)fcalc
c
        if(lnfile.eq.1)then
          call linann(ferror,linapp,napp)                               ! <-----
        else
          ferror=error
        endif
c
        if(ncolon.eq.0)then
          if(line(7:7).eq.':')ncolon=7
          if(line(6:6).eq.':')ncolon=6
          if(line(5:5).eq.':')ncolon=5
        endif
c
        if(line(90+2*lshift:90+2*lshift).ne.'*')then
          read(line(81+3*lshift:90+3*lshift),'(f10.5)',err=357)error
        else
          error=1.E10
        endif
        if(error.ge.0.0d0)then
          if(freq.lt.10000000.0d0)then
            outformat=format53
          else
            outformat=format1054
          endif
        else
          outformat=format1053
        endif
c
        if(transtyp.eq.1)then
          call ident(line,dipind,pqrind,nbreak,lshift,nqns)             ! <-----
          linapp=dipind//pqrind//linapp(1:napp)
          napp=napp+4
        endif
c
        write(3,outformat)                                              ! OUTPUT line not in fit
     *    line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *    line(nbreak+lshift:42+lshift),
     *    freq,cdiff(1:7),'UNFITTD',fcalc,linapp(1:napp)
        nlbuf=nlbuf+1                                                   ! echo to buffer for worst lines use
        write(linbufl,outformat)
     *    line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *    line(nbreak+lshift:42+lshift),
     *    freq,cdiff(1:7),'UNFITTD',fcalc,linapp(1:napp)
        linbuf(nlbuf)=linbufl(1:len_trim(linbufl))
c
c...count transitions not used in the fit into statistics bins
c
        if(freq.ne.flast.and.iabs(ibin).ne.0)then
          if(ferror.ge.0.0d0)then                                       ! MICROWAVE
            nfreu(ivlow)=nfreu(ivlow)+1
            if(ferror.ge.900.0d0)ner900(ivlow)=ner900(ivlow)+1
          else
            if(ivv(ivlow,ivup).eq.0)then                                ! new ir transition
              nvcomb=nvcomb+1
              nvstat=nvcomb
              ivv(ivlow,ivup)=nvstat
              ivindx(nvstat,1)=ivlow
              ivindx(nvstat,2)=ivup
            else
              nvstat=ivv(ivlow,ivup)
            endif
c
            nfreuir(nvstat)=nfreuir(nvstat)+1                           ! INFRARED
            if(ferror.lt.-0.9d0)ner09ir(nvstat)=ner09ir(nvstat)+1
          endif
        endif
c
c...alternative single bin statistics
c
        if(ibin.eq.0)then
          if(ferror.ge.0.0d0)then                                       ! MICROWAVE
            nfreu(1)=nfreu(1)+1
            if(ferror.ge.900.0d0)ner900(1)=ner900(1)+1
          else
            nfreuir(1)=nfreuir(1)+1                                     ! INFRARED
            if(ferror.lt.-0.9d0)ner09ir(1)=ner09ir(1)+1
          endif
        endif
c
        flast=freq
        goto 4
      endif
c
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Transition used in the fit
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c Normal:
c 185:   2  1  2  1  2  2  0  0               46429.42000   46431.42177   -2.00177    1.00000   0.00000
c 186:  48  0 48  0 47  0 47  0                28.2491800    28.2493874 -0.0002074 -0.0002000 0.0000000
c 138:  12  5  7  1 11  5  6  1              214698.74033  214698.74906   -0.00873    0.05000   0.00000  214698.74906   -0.00873 0.5000
c 139:  12  5  8  1 11  5  7  1              214698.74033  214698.74905   -0.00872    0.05000   0.00000  214698.74906   -0.00873 0.5000
c 630:  11  4  7  1 10  3  7  0                56.9091600    56.9093161 -0.0001561 -0.0002000 0.0000000    56.9093505 -0.0001905 0.5000
c 631:  11  4  8  1 10  3  8  0                56.9091600    56.9093848 -0.0002248 -0.0002000 0.0000000    56.9093505 -0.0001905 0.5000
c
c Bad obs-calc:
c 499:  66  6 61  1 65  6 60  1              596248.51667  897938.96877 -999.99999 10000000.00000   0.00000
c 500:  67  6 62  1 66  6 61  1              605568.74093  303878.33197  999.99999 999999986991104.00000   0.00000
C 501:  68  6 63  1 67  6 62  1              614913.91657  614913.95618   -0.03961 100000002004087730000.00000   0.00000
c 665:  67 12 55  0 66 12 54  0              600393.14974 1566080.57774 -999.99999 10000000.00000   0.00000 1083236.86943 -999.99999 0.5000
c 666:  67 12 56  0 66 12 55  0              600393.14974  600393.16112   -0.01139 10000000.00000   0.00000 1083236.86943 -999.99999 0.5000
c
c   if the line is a transition which has been used in the fit then increment
c   the count of lines in fit, reformat information in the line and echo the
c   line to output
c
      if(line(6:6).eq.':'.and.
     *    (line(51:51).eq.'.'.or.line(52:52).eq.'.'.or.
     *     line(50:50).eq.'.') )then
        nfreqs=nfreqs+1
c
c...write line block header if not yet done so
        if(nfreqs.eq.1.and.lseen.eq.0)then
          lseen=1
          if(line(52:52).eq.'.'.or.line(50:50).eq.'.')then
            nvers=1999
            lshift=1
          endif
          write(3,355)                                                  ! OUTPUT of line block header
355       format(1x/85('-'),9('=')
     *      /46x,'obs         o-c     error     blends     Notes'/
     *      T74,'o-c      wt'/
     *     '    / instead of : below denotes (o-c)>3*err'/
     *     85('-'),9('='))
          nqnsfit=6
          do 353 n=42+lshift,18+lshift,-6
            if(line(n:n).ne.' ')goto 354
            nqnsfit=nqnsfit-1
353       continue
354       nbreak=7+nqnsfit*3
c
          write(*,591)nqnsfit
c
c...IBIN=-555 at this stage is equivalent to not having been through the .PAR file
C
          if(ibin.eq.-555)then
            ibin=0
            nqns=nqnsfit
            if(nqns.eq.4.and.ispin.eq.0)then
              ibin=1
            else
              if(nqns.gt.4)then
594             write(*,593)
                read(*,'(i5)',err=594)idummy
                if(iabs(idummy).eq.1)ibin=idummy
                write(*,'(1x)')
              endif                                                     ! nqns>4
            endif                                                       ! nqns=4
          endif                                                         ! ibin
c
        endif                                                           ! nfreqs,lseen
c
c...read the frequency
        ediagn='EXP.FREQ.'
        read(line(43+lshift:56+lshift),'(f14.5)',err=357)freq
        if(freq.eq.flast)then
          nfreqs=nfreqs-1
          ioldbl=1
        else
          ioldbl=0
        endif
        flast=freq
      endif
c
c
c...reformat the line:
c         1/ chop out two digits from line number
c         2/ discard estimated error
c         3/ discard calc. frequency
c         4/ round estimated error to four digits
c
50    if(line(6:6).eq.':'.and.
     *    (line(51:51).eq.'.'.or.line(52:52).eq.'.'.or.
     *     line(50:50).eq.'.' ) )then
C
        ediagn='EXP.FREQ.'
        read(line(43+lshift:56+lshift),'(f14.5)',err=357)freq
        ediagn='DIFF.'
c       read(line(71+lshift:80+lshift),'(f10.5)',err=357)diff
        read(line(71+lshift:81+lshift),'(f11.5)',err=357)diff           ! correction 17.09.2025
        write(cdiff,'(f8.4)')diff
        if(cdiff(3:3).eq.' ')cdiff(3:3)='0'
        if(cdiff(3:3).eq.'-')then
          cdiff(2:2)='-'
          cdiff(3:3)='0'
        endif
C
        ediagn='EXP.ERR.'
        if(line(90+2*lshift:90+2*lshift).ne.'*')then
          read(line(81+3*lshift:90+3*lshift),'(f10.5)',err=357)error
        else
          error=1.E10
        endif
        if(error.gt.0.0d0)then
          write(cerr,'(f7.3)')error
          if(cerr(3:3).eq.' ')cerr(3:3)='0'
        else
          if(error.gt.-1.d0)then
c           write(cerr,'(f7.5)')-error                                  ! trick to avoid compiler warning
            write(cdummy,'(f9.5)')-error                                ! _/
            cerr=cdummy(3:9)
          else
            write(cerr,'(f7.2)')-error
          endif
          cerr(1:1)=' '
          write(cdiff,'(f8.5)')diff
        endif
C
        ediagn='LINE NUMBER'
        if(line(7:7).eq.':')then
          read(line(1:6),'(i6)',err=357)nlin
          ncolon=7
        endif
        if(line(6:6).eq.':')then
          read(line(1:5),'(i5)',err=357)nlin
          ncolon=6
        endif
        if(line(5:5).eq.':')then
          read(line(1:4),'(i4)',err=357)nlin
          ncolon=5
        endif
        ipt(nlin)=nlin
c
c...very large obs-calc
c
        if(line(74:82).eq.'999.99999'.or.
     *    (line(73:73).eq.'-'.and.error.ge.0.0d0))then
c
          if(lnfile.eq.1)then
            call linann(ferror,linapp,napp)                             ! <----- add annotations
          else
            ferror=error
          endif
c
          ediagn='Rereading ERROR, when large'
          read(line(83:),*,err=357)error

          ediagn='CALC.FREQ. for large DIFF.'
          read(line(57+lshift:70+lshift),'(f14.5)',err=357)fcalc
          diff=freq-fcalc
c
          if(transtyp.eq.1)then
            call ident(line,dipind,pqrind,nbreak,lshift,nqns)           ! <-----
            linapp=dipind//pqrind//linapp(1:napp)
            napp=napp+4
          endif
c
          write(3,352)                                                  ! OUTPUT of line in fit
     *      line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *      line(nbreak+lshift:42+lshift),
     *      freq,diff,cerr,fcalc,linapp(1:napp)
          ominc(nlin)=diff/error
          nlbuf=nlbuf+1                                                 ! echo to buffer for worst lines use
          write(linbufl,352)
     *      line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *      line(nbreak+lshift:42+lshift),
     *      freq,diff,cerr,fcalc,linapp(1:napp)
          linbuf(nlbuf)=linbufl(1:len_trim(linbufl))
          goto 444
        endif
352     format(a,2x,a,f12.4,f9.1,a,f13.4,1x,a)
C
C...treat every line as a potential part of a blend, and then use the value of blend
C   average frequency as blend flag
        ediagn='AVG. CALC. etc. of blended line'
        read(line(83:),*,err=1444,end=1444)
     *                                 experr,esterr,avgcalc,avgdiff,wt
c
        fcalc1=avgcalc
        diff1=avgdiff
        goto 1445
1444    fcalc1=0.0d0
        diff1=0.0d0
        wt=1.0
1445    continue
C
        if(error.gt.0.0d0)then
          write(cdiff1,'(f8.4)')diff1
          if(cdiff1(3:3).eq.' ')cdiff1(3:3)='0'
          if(cdiff1(3:3).eq.'-')then
            cdiff1(2:2)='-'
            cdiff1(3:3)='0'
          endif
        else
          write(cdiff1,'(f8.5)')diff1
        endif
C
c...transfer annotations
        if(lnfile.eq.1)then
          call linann(ferror,linapp,napp)                               ! <-----
        else
          ferror=error
        endif
c
        if(error.ge.0.0d0)then
          if(freq.lt.10000000.0d0)then
            outformat=format350
          else
            outformat=format1351
          endif
        else
          outformat=format1350
        endif
c
c...actual fitted line output
        if(fcalc1.eq.0.0d0)then                                         ! unblended line
          ominc(nlin)=diff/error
          if(dabs(ominc(nlin)).gt.3.d0)line(ncolon:ncolon)='/'
c
          if(transtyp.eq.1)then
            call ident(line,dipind,pqrind,nbreak,lshift,nqns)           ! <-----
            linapp=dipind//pqrind//linapp(1:napp)
            napp=napp+4
          endif
c
          write(3,outformat)                                            ! OUTPUT of line > 3sigma
     *     line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *     line(nbreak+lshift:42+lshift),
     *     freq,cdiff,cerr,'             '//linapp(1:napp)
          nlbuf=nlbuf+1                                                 ! echo to buffer for worst lines use
          write(linbufl,outformat)
     *     line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *     line(nbreak+lshift:42+lshift),
     *     freq,cdiff,cerr,'             '//linapp(1:napp)
          linbuf(nlbuf)=linbufl(1:len_trim(linbufl))
        else                                                            ! blended line
          if(ioldbl.eq.0)then
            ominc(nlin)=diff1/error
          else
            ominc(nlin)=0.0d0
          endif
          if(dabs(ominc(nlin)).gt.3.d0)line(ncolon:ncolon)='/'
c
          if(transtyp.eq.1)then
            call ident(line,dipind,pqrind,nbreak,lshift,nqns)           ! <-----
            linapp=dipind(2:2)//pqrind(1:1)//linapp(1:napp)
            napp=napp+2
          endif
c
          write(3,outformat)                                            ! OUTPUT of line > 3sigma
     *     line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *     line(nbreak+lshift:42+lshift),
     *     freq,cdiff,cerr,cdiff1,wt,linapp(1:napp)
          nlbuf=nlbuf+1                                                 ! echo to buffer for worst lines use
          write(linbufl,outformat)
     *     line(ncolon-nmcolon:ncolon)//line(7+lshift:nbreak-1+lshift),
     *     line(nbreak+lshift:42+lshift),
     *     freq,cdiff,cerr,cdiff1,wt,linapp(1:napp)
          linbuf(nlbuf)=linbufl(1:len_trim(linbufl))
        endif
c
c...In the special case of four or more quantum numbers, and assuming that
c       either the fourth is v (asymmetric top quanta)
c       or     the third is v (symmetric top quanta)
c   work out statistics for each value of v
c
444     if(iabs(ibin).ne.0)then
          ediagn='quantum numbers for bin statistics'
c
          if(ibin.eq.1)then                                             ! J,Ka,Kc,v quantisation
            read(line(nbreak-3*(nqns-3)+lshift:
     *                nbreak-3*(nqns-3)+2+lshift),'(i3)',err=357)ivup
            read(line(nbreak+lshift+ 9:
     *                nbreak+lshift+11),'(i3)',err=357)ivlow
          endif
c
          if(ibin.eq.-1)then                                            ! J,K,v quantisation
            read(line(nbreak-3*(nqns-2)+lshift:
     *                nbreak-3*(nqns-2)+2+lshift),'(i3)',err=357)ivup
            read(line(nbreak+lshift+ 6:
     *                nbreak+lshift+ 8),'(i3)',err=357)ivlow
          endif
c
          if(ibin.eq.-2)then                                            ! J,v quantisation
            read(line(nbreak-3*(nqns-1)+lshift:
     *                nbreak-3*(nqns-1)+2+lshift),'(i3)',err=357)ivup
            read(line(nbreak+lshift+ 3:
     *                nbreak+lshift+ 7),'(i3)',err=357)ivlow
          endif
c
          if(ioldbl.eq.0)then
            if(ibin.eq.1)then                                           ! asymmetric
              read(line(nbreak-3*(nqns-3)-9+lshift:
     *                  nbreak-3*(nqns-3)-7+lshift),'(i3)',err=357)jup
              read(line(nbreak+lshift:
     *                  nbreak+lshift+2),'(i3)',err=357)jlow
c
              read(line(nbreak-3*(nqns-3)-6+lshift:
     *                  nbreak-3*(nqns-3)-4+lshift),'(i3)',err=357)kaup
              read(line(nbreak+lshift+3:
     *                  nbreak+lshift+5),'(i3)',err=357)kalow
            endif
c
            if(ibin.eq.-1)then                                          ! symmetric
              read(line(nbreak-3*(nqns-2)-6+lshift:
     *                  nbreak-3*(nqns-2)-4+lshift),'(i3)',err=357)jup
              read(line(nbreak+lshift:
     *                  nbreak+lshift+2),'(i3)',err=357)jlow
c
              read(line(nbreak-3*(nqns-2)-3+lshift:
     *                  nbreak-3*(nqns-2)-1+lshift),'(i3)',err=357)kaup
              read(line(nbreak+lshift+3:
     *                  nbreak+lshift+5),'(i3)',err=357)kalow
c
              kaup=iabs(kaup)
              kalow=iabs(kalow)
            endif
c
            if(ibin.eq.-2)then                                          ! linear
              read(line(nbreak-3*(nqns-1)-3+lshift:
     *                  nbreak-3*(nqns-1)-1+lshift),'(i3)',err=357)jup
              read(line(nbreak+lshift:
     *                  nbreak+lshift+2),'(i3)',err=357)jlow
c
              kaup=0
              kalow=0
            endif
c
c___MICROWAVE data statistics for IVLOW bins
c
            if(ferror.gt.0.0d0)then
              if(jup  .gt. maxj(ivlow)) maxj(ivlow)=jup
              if(jlow .gt. maxj(ivlow)) maxj(ivlow)=jlow
              if(kaup .gt. maxk(ivlow)) maxk(ivlow)=kaup
              if(kalow.gt. maxk(ivlow)) maxk(ivlow)=kalow
              if(jup  .lt. minj(ivlow)) minj(ivlow)=jup
              if(jlow .lt. minj(ivlow)) minj(ivlow)=jlow
              if(kaup .lt. mink(ivlow)) mink(ivlow)=kaup
              if(kalow.lt. mink(ivlow)) mink(ivlow)=kalow
              if(freq .lt. flow(ivlow)) flow(ivlow)=freq
              if(freq .gt.fhigh(ivlow))fhigh(ivlow)=freq
c
              if(ivlow.eq.ivup)then
                nfre(ivlow)=nfre(ivlow)+1
              else
                nfred(ivlow)=nfred(ivlow)+1
c               write(*,'(2x,3i4,3x,3i4)')jup,kup,ivup,jlow,klow,ivlow
              endif
c
              sdev(ivlow) =sdev(ivlow) +(ominc(nlin)*error)**2
              swdev(ivlow)=swdev(ivlow)+ ominc(nlin)**2
              if(ferror.gt.900.0d0)ner900(ivlow)=ner900(ivlow)+1
            endif
c
c___INFRARED data statistics for IVLOW,IVUP bins
c
            if(ferror.lt.0.0d0)then
              if(ivv(ivlow,ivup).eq.0)then                              ! new ir transition
                nvcomb=nvcomb+1
                nvstat=nvcomb
                ivv(ivlow,ivup)=nvstat
                ivindx(nvstat,1)=ivlow
                ivindx(nvstat,2)=ivup
              else
                  nvstat=ivv(ivlow,ivup)
              endif
c
              if(jup  .gt. irmaxj(nvstat)) irmaxj(nvstat)=jup
              if(jlow .gt. irmaxj(nvstat)) irmaxj(nvstat)=jlow
              if(kaup .gt. irmaxk(nvstat)) irmaxk(nvstat)=kaup
              if(kalow.gt. irmaxk(nvstat)) irmaxk(nvstat)=kalow
              if(jup  .lt. irminj(nvstat)) irminj(nvstat)=jup
              if(jlow .lt. irminj(nvstat)) irminj(nvstat)=jlow
              if(kaup .lt. irmink(nvstat)) irmink(nvstat)=kaup
              if(kalow.lt. irmink(nvstat)) irmink(nvstat)=kalow
              if(freq .lt. flowir(nvstat)) flowir(nvstat)=freq
              if(freq .gt.fhighir(nvstat))fhighir(nvstat)=freq
c
              if(ivlow.eq.ivup)then
                nfreir(nvstat)=nfreir(nvstat)+1
              else
                nfreird(nvstat)=nfreird(nvstat)+1
              endif
              sdevir (nvstat)=sdevir (nvstat)+(ominc(nlin)*error)**2
              swdevir(nvstat)=swdevir(nvstat)+ ominc(nlin)**2
              if(ferror.lt.-0.9d0)ner09ir(nvstat)=ner09ir(nvstat)+1
            endif
c
          endif                                                         ! ioldbl
        endif                                                           ! 444 if
c
c...alternative single bin statistics
c
        if(ibin.eq.0)then
          if(freq .lt. flow(1)) flow(1)=freq
          if(freq .gt.fhigh(1))fhigh(1)=freq
c
          ediagn='q.nums for alternative bin statistics'
          read(line(ncolon+2:),'(20i3)',err=357)(nqnup(jj),jj=1,nqns),
     *                                  (nqlow(jj),jj=1,nqns)
          do 445 jj=1,nqns
            if(nqlow(jj).lt.minlow(jj))minlow(jj)=nqlow(jj)
            if(nqnup(jj).lt.minup (jj))minup (jj)=nqnup(jj)
            if(nqlow(jj).gt.maxlow(jj))maxlow(jj)=nqlow(jj)
            if(nqnup(jj).gt.maxup (jj))maxup (jj)=nqnup(jj)
445       continue
c
          if(ferror.gt.900.0d0)ner900(1)=ner900(1)+1
c
        endif
c
        goto 4                                                          ! read next .FIT line
      endif                                                             ! 50 if (line reformatting loop)
c
c...read a new line of input if no transitions have yet been identified
c
      if(lseen.eq.0)goto 4                                              ! read next .FIT line
c
c . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
c
c...new set of parameters will follow so write their header
c
      if(line(33:45).eq.'NEW PARAMETER')then
        if(lnfile.eq.1)rewind(4)
        if(lrejct.eq.0)then
          write(3,'(80(''-''))')
        else
          lrejct=0
        endif
        write(3,'(1x/a/a)')
     *   'PARAMETERS IN FIT (values truncated and Nlines statistics):'
        goto 4                                                          ! read next .FIT line
      endif
c
      if(line(2:10).eq.'MICROWAVE')then
        if(iflag.eq.1)then
          write(3,'(1x)')
          iflag=0
        endif
        write(3,'(a)')line(1:78)
        goto 4                                                          ! read next .FIT line
      endif
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c  State by state statistics followed by parameters with standard errors
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
c   The end of a block of parameters so output the values of
c   all fitted parameters again but this time with standard errors
c
c   standard errors are obtained by multiplying errors from fit by:
c       (RMS ERROR)*SQRT( N.lines/ (N.lines-N.fittedconsts) )
c   and the RMS deviation of fit with measurement errors multiplied by this
c   factor would be
c       SQRT( (N.lines-N.fittedconsts)/N.lines )
c
c
      if(line(2:17).eq.'END OF ITERATION')then
        ediagn='RMS ERROR'
        read(line(56:71),'(f20.6)',err=357)rmserr
        sterr=rmserr*dsqrt( dble(nfreqs) / dble(nfreqs-nfitc) )
        write(3,'(a/)')line(1:78)
c
        if(nparlin.ne.0)write(3,455)nparlin
455     format('      number of .LIN lines to fit:',i6 )        
        write(3,55)nfreqs,nfitc
55      format('  distinct frequency lines in fit:' ,i6/
     *         '       distinct parameters of fit: ',i5)
c
        if(nrejl.gt.0)then
          write(3,255)nrejl,errtst
          nrejl=0
        endif
255     format('  UNFITTD lines rejected from fit: ',i5,
     *         '    (@ ERRTST =',1pE10.2,')')
c
        if(ibin.eq.0.and.ner900(1).gt.0)then
          write(3,256)ner900(1)
        endif
256     format('                lines with e>=900: ',i5)
c
c
c...alternative single bin statistics
c
      if(ibin.eq.0)then
        write(3,'(1x/a,a)')
     *   '                                    upper state  lower state',
     *   '         overall'
        do 5025 nn=1,nqns

          write(3,5027)nn,minup(nn),maxup(nn),minlow(nn),maxlow(nn),
     *                 min0(minup(nn),minlow(nn)),
     *                 max0(maxup(nn),maxlow(nn))
5025    continue
5027    format(    '      limits of quantum number',i3,':',i7,i5,i8,i5,
     *    i12,i5)
c
        write(3,5028)int(flow(1)),int(fhigh(1))
5028    format(1x/'                  frequency range:',i12,i13)
        goto 5022
      endif
c
c
c...Microwave state by state:
c
c   NOTE: subset statistics are for NLINES statistics for compatibility with
c         values printed in the .FIT file. There should be good agreement of
c         total RMS and RMS ERROR evaluated here with MICROWAVE RMS and 
c         NEW RMS ERROR printed in the .FIT (providing obs-calc values are read
c         to five digits after the decimal point)
c
c         A small difference  (not accounted for properly by PIFORM) may arise
c         if blend components are declared with different measurement uncertainties.
c
        nfretot=0
        do 5004 nn=0,maxv
          nfretot=nfretot+nfre(nn)+nfred(nn)
5004    continue
c
        if(nfretot.gt.0)write(3,160)                                    ! MICROWAVE column header
160     format(1x/'MICROWAVE       lines fitted       lines    lines',
     *   '      RMS      RMS ERROR    J range  Ka range    freq. range'/
     *'            total   dv=0 dv.ne.0   UNFITTD  e>=900')
c
        do 5005 nn=0,maxv
          if(nfre(nn).gt.0.or.nfred(nn).gt.0)then
            sdev(nn)= dsqrt(sdev(nn) /(nfre(nn)+nfred(nn)))
            swdev(nn)=dsqrt(swdev(nn)/(nfre(nn)+nfred(nn)))
            write(3,159)nn,nfre(nn)+nfred(nn),nfre(nn),nfred(nn),       ! OUTPUT of MICROWAVE statistics
     *                     nfreu(nn),ner900(nn),sdev(nn),swdev(nn),
     *                     minj(nn),maxj(nn),mink(nn),maxk(nn),
     *                     nint(flow(nn)),nint(fhigh(nn))
          endif
5005    continue
c
c...microwave totals
c
        if(nfretot.gt.0)then
          sdevtot=0.0d0
          swdevtot=0.0d0
          nfrevtot=0
          nfredvtot=0
          nfreutot=0
          nver900t=0
          do 5006 nn=0,maxv
            sdevtot= sdevtot   +sdev(nn)**2 *(nfre(nn)+nfred(nn))
            swdevtot= swdevtot +swdev(nn)**2*(nfre(nn)+nfred(nn))
            nfrevtot= nfrevtot +nfre(nn)
            nfredvtot=nfredvtot+nfred(nn)
            nfreutot= nfreutot +nfreu(nn)
            nver900t= nver900t +ner900(nn)
5006      continue
          sdevtot=dsqrt(sdevtot/nfretot)
          swdevtot=dsqrt(swdevtot/nfretot)
          write(3,165)nfretot,nfrevtot,nfredvtot,nfreutot,nver900t,     ! OUTPUT of MICROWAVE totals
     *                sdevtot,swdevtot
        endif
c
159     format('v"=',i2,i11,2i7,i9,i7,F15.6,F12.5,i6,i4,i5,i4,2i9)
165     format(92(1H-)/
     *  'total:',    i10,2i7,i9,i7,F15.6,F12.5  )
c
c
c
c...infrared state by state
c
        nfreirtot=0
        do 5007 nn=0,maxvm
          nfreirtot=nfreirtot+nfreir(nn)+nfreird(nn)
5007    continue
c
        if(nfreirtot.gt.0)write(3,161)
161     format(1x/'INFRARED        lines fitted       lines    lines',  ! INFRARED column header
     *  '      RMS      RMS ERROR    J range  Ka range    waven. range'/
     *'            total   dv=0 dv.ne.0   UNFITTD  e<-0.9')
c
        do 5008 nn=0,maxvm
          if(nfreir(nn).gt.0.or.nfreird(nn).gt.0)then
            sdevir(nn)=dsqrt( sdevir(nn) /(nfreir(nn)+nfreird(nn)))
            swdevir(nn)=dsqrt(swdevir(nn)/(nfreir(nn)+nfreird(nn)))
            write(3,162)ivindx(nn,2),ivindx(nn,1),                      ! OUTPUT of INFRARED statistics
     *                nfreir(nn)+nfreird(nn),nfreir(nn),nfreird(nn),
     *                nfreuir(nn),ner09ir(nn),sdevir(nn),swdevir(nn),
     *                irminj(nn),irmaxj(nn),irmink(nn),irmaxk(nn),
     *                flowir(nn),fhighir(nn)
          endif
5008    continue
162     format(i2,'<-',i2,i10,2i7,i9,i7,F16.7,F11.5,i6,i4,i5,i4,2f9.2)
c
c...infrared totals
c
        if(nfreirtot.gt.0)then
          sdevirtot=0.0d0
          swdevirtot=0.0d0
          nvtotir=0
          ndvtotir=0
          nutotir=0
          nv09tir=0
          do 5009 nn=0,maxvm
            sdevirtot=
     *               sdevirtot +sdevir(nn)**2 *(nfreir(nn)+nfreird(nn))
            swdevirtot=
     *               swdevirtot+swdevir(nn)**2*(nfreir(nn)+nfreird(nn))
            nvtotir= nvtotir +nfreir(nn)
            ndvtotir=ndvtotir+nfreird(nn)
            nutotir= nutotir +nfreuir(nn)
            nv09tir= nv09tir +ner09ir(nn)
5009      continue
          sdevirtot=dsqrt(sdevirtot/nfreirtot)
          swdevirtot=dsqrt(swdevirtot/nfreirtot)
          write(3,1165)nfreirtot,nvtotir,ndvtotir,nutotir,nv09tir,      ! OUTPUT of INFRARED totals
     *                sdevirtot,swdevirtot
        endif
c
1165    format(92(1H-)/
     *         'total:',    i10,2i7,i9,i7,F16.7,F11.5  )
c
        if(nfretot+nfreirtot.gt.0)then
          write(3,1166)
1166      format(1x/
     *  'NOTE: the RMS and RMS ERROR values directly above are for',
     *    ' Nlines statistics, for consistency with '/
     *  '      the RMS and NEW RMS ERROR values as printed in the ',
     *  '.FIT file.')
        endif
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Rewrite all parameters changing those with errors to standard errors.
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C
C   Previous output for parameter n is stored in LINOUT(n), which is not
C   altered for a fixed parameter and only the parameter value and error fields
c   are modified for a fitted parameter.
c   Values of fitted parameters are also (iteratively) rounded.
c
5022    write(3,'(1x)')
        if(frac.lt.0.0d0)then
          write(3,155)abs(frac)
          sterr=1.d0/abs(frac)
          write(3,158)sterr
          write(3,171)
        else
          if(frac.eq.0.0d0)then
            write(*,'(//'' **** ERROR: FRAC=0 was used''//)')
            stop
          endif
          sterr=sterr/frac
          if(frac.ne.1.0d0)write(3,157)frac
        endif
c
158     format(
     *   ' Standard errors are obtained by muliplying ',
     *   'the previous errors by: ',f10.6)
155     format(' FRAC<0 was used so that the errors above are',F8.4,
     *         ' times the standard error')
171     format(/' NOTE: the standard errors as printed below may ',
     *    'not be exact. Please read'/
     *     '       the comments on negative FRAC in the Crib_sheet.'/)
157     format(' NOTE: the conversion factor incorporates FRAC=',f10.6/)
c
        write(3,156)
156     format(1x/
     *   ' PARAMETERS IN FIT WITH STANDARD ERRORS ON THOSE THAT ARE ',
     *   'FITTED:'/
     * ' (values rounded and degrees of freedom, Ndegf=Nlines-Nconst,',
     * ' statistics)'/)
c
        do 415 n=1,nout
c
c...deal with a fitted parameter (rounding as coded tends in rare cases to go into
c                                an infinite loop, hence the NITER cludge)
c
          if(ercons(n).ne.0.0d0)then
            niter=0
417         WRITE(CONVAL,'(F27.16)')constv(n)
            WRITE(ERVAL,'(F27.16)')ercons(n)*sterr
c           write(3,*)conval,erval                                      ! debug
            CALL CONFOR(CONVAL,ERVAL,NDCON,NDEROR,nerd)                 ! <-----
            if(conval(ndcon+1:ndcon+1).eq.'5'.or.                       ! rounding of values
     *         conval(ndcon+1:ndcon+1).eq.'6'.or.
     *         conval(ndcon+1:ndcon+1).eq.'7'.or.
     *         conval(ndcon+1:ndcon+1).eq.'8'.or.
     *         conval(ndcon+1:ndcon+1).eq.'9')then
c              write(*,'(1x,2a,i8,f27.16)')conval,conval(1:ndcon),ndcon,
c    *                                             10.d0**(-(ndcon-10))
               constv(n)=constv(n)+
     *                       dsign(1.d0,constv(n))*10.0d0**(-(ndcon-10))
               niter=niter+1
               if(niter.le.5)goto 417
            endif
c
            if(ndcon+nderor.gt.40)then                                  ! debug
              WRITE(lintest,518)CONVAL(1:NDCON),ERVAL(1:NDEROR)         ! debug
              write(*,'(1x,a/1x,a)')                                    ! debug
     *            'WARNING --> string length overflow'//                ! debug
     *            ' on an unusual value of parameter:',                 ! debug
     *            lintest(1:len_trim(lintest))                          ! debug
              write(*,'(1x,a//1x,a,3x)',advance='NO')                   ! debug
     *              'Problems expected - untested condition !',         ! debug
     *              'Press ENTER to continue'                           ! debug
              read(*,*,err=9999)idummy                                  ! debug
9999          continue                                                  ! debug
            endif                                                       ! debug
c
            write(cwork,518)CONVAL(1:NDCON),ERVAL(1:NDEROR)
518         format(a,'(',a,')')
            write(linout(n)(36:65),'(29('' ''))')
            linout(n)(36:65)=cwork(1:len_trim(cwork))
          endif
c
c...unified output for fitted and fixed parameter
          write(3,'(a)')linout(n)                                       ! OUTPUT of parameter (st.error)
c
c...percentage error
          if(constv(n).ne.0.d0)then
            rtemp=dabs(ercons(n)*sterr/constv(n))*100.0d0
          else
            rtemp=0.d0
          endif 
          if(rtemp.ge.cperc)then
            nworstc=nworstc+1
            worstcon(nworstc)=linout(n)
            wperc(nworstc)=rtemp
          endif
c
          if(nsepl(n).eq.1)write(3,'(1x)')
415     continue
c
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c...Worst fitted parameters
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
        if(nworstc.gt.0)then
          write(3,7714)nint(cperc)
7714      format(1x/90(1H-)/
     *    ' Worst fitted parameters, with greater than',i3,
     *    '% uncertainty:',28x,'%'/)
          do 7715 n=1,nworstc
            write(3,7716)worstcon(n)(1:len_trim(worstcon(n))),wperc(n)  ! OUTPUT of worst parameters
7715      continue
          write(3,7717)
        endif
7716    format(a,f10.1)
7717    format(90(1H-))
        nworstc=0
c
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Correlation matrix
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
c...discard leading blanks from parameter names in CNAMES for use in
c   the correlation matrix row and column headers
c
c       if(nvers.eq.1999)then
          do 450 n=1,ncon
            do 451 nn=1,10
              if(cnames(n)(nn:nn).ne.' ')goto 452
451         continue
452         if(nn.le.10)cnames(n)=cnames(n)(nn:10)
450       continue
c       endif
c
c...read from the .FIT file and write out the reformatted correlation matrix
c
        call corelm(int(nfitc),nout)                                    ! <-----
c
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Worst fitted lines
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
        call worstl(nlin,nmcolon)                                       ! <-----
c
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Reset prior to possible next iteration of fit in the .FIT file
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
        nfitc=0
        nfreqs=0
        nlbuf=0
        lrejct=0
        nvcomb=0
        nvstat=0
        ibin=-555
c
        do 5017 nn=1,maxvst
          ivindx(nn-1,1)=0
          ivindx(nn-1,2)=0
          do 5018 nnn=1,maxvst
            ivv(nn-1,nnn-1)=0
5018      continue
5017    continue
c
        do 5021 nn=1,maxqn
          minup(nn) = 1000
          minlow(nn)= 1000
          maxlow(nn)=-1000
          maxup(nn) =-1000
5021    continue
c                                                                       ! MICROWAVE:                   
        do 5010 nn=0,maxv                                                                              
          nfre(nn)=0                                                    ! fitted, dv=0                 
          nfred(nn)=0                                                   ! fitted, dv.ne.0              
          nfreu(nn)=0                                                   ! unfitted                     
          ner900(nn)=0                                                  ! excluded with large error    
          sdev(nn)=0                                                    ! deviation                    
          swdev(nn)=0                                                   ! rms deviation                
          maxk(nn)=0
          maxj(nn)=0
          mink(nn)=500
          minj(nn)=500
5010    continue
c                                                                       ! INFRARED:                                                   
        do 5011 nn=0,maxvm                                                                                 
          nfreir(nn)=0                                                  ! fitted, dv=0                     
          nfreird(nn)=0                                                 ! fitted, dv.ne.0                  
          nfreuir(nn)=0                                                 ! unfitted                         
          ner09ir(nn)=0                                                 ! excluded with large error        
          sdevir(nn)=0.0d0                                              ! deviation                        
          swdevir(nn)=0.0d0                                             ! rms deviation                    
          irmink(nn)=500
          irmaxk(nn)=0
          irminj(nn)=500
          irmaxj(nn)=0
          flowir(nn)=1.d20
          fhighir(nn)=-1.d20
5011    continue
c
        lseen=0
        flast=0
        nout=0
        nsepl(1)=0
        goto 4                                                          ! read next .FIT line
      endif
c
c...line is of no interest so advance to next line of input
c
      if(line(4:4).eq.' ')goto 4                                        ! read next .FIT line
      read(line,'(i4)',err=4)i
      if(i.eq.0)goto 4                                                  ! read next .FIT line
      if(line(5:5).ne.' ')goto 4                                        ! read next .FIT line
c
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Parameters as printed
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
c...The following is executed only if none of the previous conditions has been
c   satisfied and the line contains a value of a parameter
c
c...establish version number of SPFIT by testing the character in column 20
c   (C-type 1999 version is determined earlier on reading in transitions)
c
      if(nvers.eq.0)then
        nvers=1995
        if(line(20:20).eq.'.')nvers=1997
      endif
c
      if(nvers.eq.1995)then
        read(line(32:49),'(f25.10)',err=4)const
        read(line(50:65),'(f25.10)',err=4)error
        read(line(1:4),'(i4)')ncon
        read(line(20:30),'(a10)')cnames(ncon)
        read(line(7:16),'(a10)')cident(ncon)
        if(cident(ncon).eq.'         0')cident(ncon)='        00'
      endif
c
      if(nvers.eq.1997)then
        read(line(35:53),'(f26.10)',err=4)const
        read(line(54:69),'(f25.10)',err=4)error
        read(line(1:4),'(i4)')ncon
        read(line(24:34),'(a10)')cnames(ncon)
        read(line(10:19),'(a10)')cident(ncon)
        if(cident(ncon).eq.'         0')cident(ncon)='        00'
      endif
c
c  MM accounts for two character shift to the left of the four rightmost
c  columns that took place around 2002
c  NODOT=1 accounts for no dot after the parameter identifier that used to be
c  in earlier SPFIT versions
C
      if(nvers.eq.1999)then
        mm=0
        if(line(19:19).eq.' '.and.line(19:21).ne.' 0 ')mm=-2
c
        if(line(54+mm:57+mm).eq.'   ')line(54+mm:57+mm)='E+00'
c       if(line(50+mm:50+mm).eq.' ')line(50+mm:50+mm)='0'
        nodot=1
        do 590 n=32+mm,48+mm
          if(line(n:n).eq.'.')nodot=0
590     continue
c
        if(nodot.eq.0)then
          cwork=line(32+mm:48+mm)//line(54+mm:57+mm)
        else
          cwork=line(32+mm:48+mm)//'.'//line(54+mm:57+mm)
          multer=0
        endif
c
        if(line(53+mm:53+mm).eq.')')then
          read(cwork,'(f25.10)',err=4)const                             ! read value of parameter
          cwork=line(50+mm:52+mm)//'.0'//line(54+mm:57+mm)
c         read(cwork(1:9),'(f9.8)',err=4)error                          ! trick to avoid compiler warning
          cdummy='  '//cwork(1:9)                                       ! _/
          read(cdummy(1:11),'(f11.8)',err=4)error                       ! read value of error
        else
          cwork=line(32+mm:48+mm)
          read(cwork,'(f25.0)',err=4)const
          do 700 n=50+mm,70
            if(line(n:n).eq.')')then
              ierfin=n-1
              goto 701
            endif
700       continue
          goto 4
701       cwork=line(50+mm:ierfin)
          read(cwork,'(f25.0)',err=4)error
        endif
c
        if(nodot.eq.1)goto 401
c
        do 400 n=32+mm,48+mm
          if(line(n:n).eq.'.')then
            multer=48+mm-n
            goto 401
          endif
400     continue
c
401     error=error*10.0d0**(dble(-multer))
        read(line(1:4),'(i4)')ncon
        read(line(22+mm:31+mm),'(a10)')cnames(ncon)
        read(line(11+mm:20+mm),'(a10)')cident(ncon)
        if(cident(ncon).eq.'         0')cident(ncon)='        00'
        read(line(5:),*)idpar(ncon)
      endif
c
c...identify the first character in parameter's name and prescale to customary
c   units
c
c           quartic - kHz, sextic - Hz, octic,decadic - mHz, all other - MHz
c
      write(*,'(1x,a)')line(1:78)
      iflag=1
      if(nvers.eq.1995)then
        do 100 n=17,31
          if(line(n:n).ne.' ')goto 101
100     continue
      endif
      if(nvers.eq.1997)then
        do 102 n=21,34
          if(line(n:n).ne.' ')goto 101
102     continue
      endif
      if(nvers.eq.1999)then
        do 103 n=21+mm,31+mm
          if(line(n:n).ne.' ')goto 101
103     continue
      endif
c
c...quadratic
c
101   ascld=const
      escld=error
      unit='MHz '
c
c...quartic (implicit unit is kHz)
c
c   also if name begins with a minus then change sign of the value of the parameter
c   and erase the minus from its descriptor
c
c   for the dependent parameters the descriptor is corrected on filling out
c   PNAMES when reading the top of the .FIT file
c
c
      if(line(n:n).eq.'d'.or.
     *         (line(n:n).eq.'-'.and.line(n+1:n+1).eq.'D')
     *    .or. (line(n:n).eq.'-'.and.line(n+1:n+1).eq.'d')
     *    .or. (line(n:n).eq.'D'.and.line(n+1:n+1).eq.'2')
     *    .or. (line(n:n).eq.'d'.and.line(n+1:n+1).eq.'2'))then
        ascld=const*1.e+3
        escld=error*1.e+3
        unit='kHz '
c
        if(line(n:n).eq.'-')then
          line(n:n)=' '
          ascld=-ascld
        endif
      endif
c
c...sextic (implicit unit is Hz)
c
      if(line(n:n).eq.'H'.or.line(n:n).eq.'h'
     *    .or.line(n:n+2).eq.'phi'.or.line(n:n+2).eq.'Phi'
     *    .or. (line(n:n).eq.'D'.and.line(n+1:n+1).eq.'3')
     *    .or. (line(n:n).eq.'d'.and.line(n+1:n+1).eq.'3'))then
        ascld=const*1.e+6
        escld=error*1.e+6
        unit='Hz  '
      endif
c
c...octic (implicit unit is mHz)
c
      if(line(n:n).eq.'L'.or.line(n:n).eq.'l'
     *    .or. (line(n:n).eq.'D'.and.line(n+1:n+1).eq.'4')
     *    .or. (line(n:n).eq.'d'.and.line(n+1:n+1).eq.'4'))then
        ascld=const*1.e+9
        escld=error*1.e+9
        unit='mHz '
      endif
c
c...decadic (implicit unit is mHz)
c
      if(      line(n:n+1).eq.'PJ'.or.line(n:n+1).eq.'PK'
     *    .or. line(n:n+1).eq.'pJ'.or.line(n:n+1).eq.'pK'
     *    .or. line(n:n+1).eq.'Pj'.or.line(n:n+1).eq.'Pk'
     *    .or. line(n:n+1).eq.'pj'.or.line(n:n+1).eq.'pk'
     *    .or. line(n:n+1).eq.'p1'.or.line(n:n+1).eq.'p2'
     *    .or. line(n:n+1).eq.'p3'.or.line(n:n+1).eq.'p4'
     *    .or. line(n:n+1).eq.'p5'                          
     *    .or. (line(n:n).eq.'D'.and.line(n+1:n+1).eq.'5')
     *    .or. (line(n:n).eq.'d'.and.line(n+1:n+1).eq.'5'))then
        ascld=const*1.e+9
        escld=error*1.e+9
        unit='mHz '
      endif
c
c...higher order parameters than octic for linear molecules
c
      if(cident(ncon)(8:10).eq.'500')then
        ascld=const*1.e+12
        escld=error*1.e+12
        unit='uHz '
      endif
      if(cident(ncon)(8:10).eq.'600')then
        ascld=const*1.e+15
        escld=error*1.e+15
        unit='nHz '
      endif
      if(cident(ncon)(8:10).eq.'700')then
        ascld=const*1.e+18
        escld=error*1.e+18
        unit='pHz '
      endif
      if(cident(ncon)(8:10).eq.'800')then
        ascld=const*1.e+21
        escld=error*1.e+21
        unit='fHz '
      endif
      if(cident(ncon)(8:10).eq.'900')then
        ascld=const*1.e+24
        escld=error*1.e+24
        unit='aHz '
      endif
c
c...determination whether fixed or fitted parameter
c
c     if(abs(const).lt.1.1E-17)then
      if(abs(const).lt.1.1D-31)then
        escld=0.0d0
        ascld=0.0d0
        goto 1003                                                       ! go to CONFIX
      endif
c     if(error.lt.1.0E-19)then
      if(error.lt.1.1D-35)then
        escld=0.0d0
        goto 1003                                                       ! go to CONFIX
      endif
c
c...decrease unit if the fitted parameter is still in MHz but is too small
c
      if(ascld.eq.const)then
        if(error.lt.1.d-14)then
          ascld=const*1.e+3
          escld=error*1.e+3
          unit='kHz '
        endif
        if(escld.lt.1.d-14)then
          ascld=const*1.e+6
          escld=error*1.e+6
          unit='Hz  '
        endif
        if(escld.lt.1.d-14)then
          ascld=const*1.e+9
          escld=error*1.e+9
          unit='mHz '
        endif
        if(escld.lt.1.d-14)then
          ascld=const*1.e+12
          escld=error*1.e+12
          unit='uHz '
        endif
        if(escld.lt.1.d-14)then
          ascld=const*1.e+15
          escld=error*1.e+15
          unit='nHz '
        endif
      endif
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c   Fitted parameter
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C
C...deal with value of parameter carrying an error - put the specified number
c   of digits of error in brackets on output
c
c   writing to internal file tends to decrement by one digit of double
c   precision resolution - hence the 1D-14 correction
c
          WRITE(CONVAL,'(F27.16)')ascld+1.D-14*ascld
          WRITE(ERVAL,'(F27.16)')escld+1.D-14*escld
          CALL CONFOR(CONVAL,ERVAL,NDCON,NDEROR,nerd)                   ! <-----
          if(nderor.eq.0)goto 1003                                      ! go to CONFIX
c
c...insert line separating blocks of parameters with different vibrational
c   indices
c
          if(ncon.gt.1)then
            now=cident(ncon)
            last=cident(ncon-1)
c           if( (now(9:10).ne.last(9:10).and.last(9:9).eq.last(10:10))
c    *           .or.now(8:8).eq.' ')then
            if( now(9:10).ne.last(9:10))then
              write(3,'(1x)')                                           ! OUTPUT line separating patameters
              nsepl(nout)=1
            endif
          endif
c
c...actual output of formatted parameters with error
c
          nout=nout+1
          constv(nout)=ascld+1.D-14*ascld
          ercons(nout)=escld+1.D-14*escld
c
          if(nvers.eq.1995)then
            WRITE(3,411)line(5:16),line(17:31),UNIT,CONVAL(1:NDCON),    ! OUTPUT fitted parameter 1995
     *                  ERVAL(1:NDEROR)
            WRITE(linout(nout),411)
     *                  line(5:16),line(17:31),UNIT,CONVAL(1:NDCON),
     *                  ERVAL(1:NDEROR)
          endif
c
          if(nvers.eq.1997)then
            WRITE(3,411)line(5:19),line(21:34),UNIT,CONVAL(1:NDCON),    ! OUTPUT fitted parameter 1997
     *                  ERVAL(1:NDEROR)
            WRITE(linout(nout),411)
     *                  line(5:19),line(21:34),UNIT,CONVAL(1:NDCON),
     *                  ERVAL(1:NDEROR)
          endif
c
          if(nvers.eq.1999)then
            read(line(2:4),'(i3)')nn
c
c...remove scaling to smaller units than MHz if formatted output string is too long
c
            WRITE(lintest,4411)
     *                  line(6:20+mm),line(21+mm:33+mm),UNIT,
     *          CONVAL(1:NDCON),ERVAL(1:NDEROR),nn
4411        FORMAT(     A,2x,A,'/',A,2x,A,'(',A,') ',i3)
            if(ndcon+nderor.gt.38.or.len_trim(lintest).gt.80)then
              write(*,'(1x,a/1x,a)')
     *            'WARNING --> MHz units restored for'//
     *            ' this parameter due to string length overflow:',
     *            lintest(1:len_trim(lintest))
              ascld=const
              escld=error
              unit='MHz '
              WRITE(CONVAL,'(F27.16)')ascld+1.D-14*ascld
              WRITE(ERVAL,'(F27.16)')escld+1.D-14*escld
              CALL CONFOR(CONVAL,ERVAL,NDCON,NDEROR,nerd)               ! <-----
              constv(nout)=ascld+1.D-14*ascld
              ercons(nout)=escld+1.D-14*escld
            endif
c
c                        identifier        name
c                        |                 |
            WRITE(3,411)line(6:20+mm ),line(21+mm :33+mm ),UNIT,        ! OUTPUT fitted parameter 1999
     *          CONVAL(1:NDCON),ERVAL(1:NDEROR),nn
            WRITE(linout(nout),411)
     *                  line(6:20+mm ),line(21+mm :33+mm ),UNIT,
     *          CONVAL(1:NDCON),ERVAL(1:NDEROR),nn
c
c...additional lines for dependent parameters
            do 48 i=1,npared-1
              if(infpar(i,2).eq.nn)then
                jj=i
49              jj=jj+1
                if(infpar(jj,2).eq.nn)then
                  WRITE(CONVAL,'(F27.16)')
     *                            (ascld+1.D-14*ascld)*conmul(jj)
                  WRITE(ERVAL,'(F27.16)')
     *                           (escld+1.D-14*escld)*abs(conmul(jj))
                  CALL CONFOR(CONVAL,ERVAL,NDCON,NDEROR,nerd)           ! <-----
                  nout=nout+1
c
                  if(iabs(nvib).le.9)then
                    write(3,418)numpar(jj),pnames(jj),UNIT,               ! OUTPUT dependent parameter
     *                          CONVAL(1:NDCON),ERVAL(1:NDEROR),          ! for nvib<10
     *                          conmul(jj),infpar(jj,2)
                    write(linout(nout),418)
     *                          numpar(jj),pnames(jj),UNIT,
     *                          CONVAL(1:NDCON),ERVAL(1:NDEROR),
     *                          conmul(jj),infpar(jj,2)
                    constv(nout)=(ascld+1.D-14*ascld)*conmul(jj)
                    ercons(nout)=(escld+1.D-14*escld)*abs(conmul(jj))
                  else
                    write(3,419)numpar(jj),pnames(jj),UNIT,               ! OUTPUT dependent parameter
     *                          CONVAL(1:NDCON),ERVAL(1:NDEROR),          ! for nvib>9
     *                          conmul(jj),infpar(jj,2)
                    write(linout(nout),419)
     *                          numpar(jj),pnames(jj),UNIT,
     *                          CONVAL(1:NDCON),ERVAL(1:NDEROR),
     *                          conmul(jj),infpar(jj,2)
                    constv(nout)=(ascld+1.D-14*ascld)*conmul(jj)
                    ercons(nout)=(escld+1.D-14*escld)*abs(conmul(jj))
                  endif
c
                  if(jj.ge.npared)goto 51
                  goto 49
                else
                  goto 51
                endif
              endif
48          continue
51          continue
          endif
411   FORMAT(     A,2x,A,'/',A,2x,A,'(',A,') ',t78,i3)
418   FORMAT(i13,3x,A,2x,'/',A,2x,A,'(',A,')',T66,'=',F9.5,T77,'*',i3)
419   FORMAT(i15,3x,A,2x,'/',A,2x,A,'(',A,')',T66,'=',F9.5,T77,'*',i3)
c
          nfitc=nfitc+1
          infitc(nfitc)=ncon
c
c...backspace NFITC for dependent parameter
c
          if(nvers.eq.1995)then
            read(cident(ncon),'(i10)')concod
            if(nfitc.gt.1.and.concod.lt.0)then
              nfitc=nfitc-1
            endif
          else
            if(nfitc.gt.1.and.infitc(nfitc-1).eq.ncon)then
              nfitc=nfitc-1
            endif
          endif
c
          GOTO 4
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C   Fixed parameter
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
C   Deal with value of a fixed parameter, ie. error is vanishingly small.
c   Formatting is carried out to insert a zero before
C   the decimal point, to discard digits from rounding errors, and put the
c   whole value in square brackets
c
1003  call CONFIX(const,ascld,conval,iend)                              ! <-----
c
c...insert line separating blocks of parameters with different vibrational
c   indices
          if(ncon.gt.1)then
            now=cident(ncon)
            last=cident(ncon-1)
c           if( (now(9:10).ne.last(9:10).and.last(9:9).eq.last(10:10))
c    *           .or.now(8:8).eq.' ')write(3,'(1x)')
            if( now(9:10).ne.last(9:10))then
              write(3,'(1x)')
              nsepl(nout)=1
            endif
          endif
c
c...actual output of formatted parameter without error
c
          nout=nout+1
          ercons(nout)=0.0d0
c
          if(nvers.eq.1995)then
            WRITE(3,1005)line(5:16),line(17:31),UNIT,CONVAL(1:iend)     ! OUTPUT fixed parameter 1995
            WRITE(linout(nout),1005)
     *                   line(5:16),line(17:31),UNIT,CONVAL(1:iend)
          endif
c
          if(nvers.eq.1997)then
            WRITE(3,1005)line(5:19),line(21:34),UNIT,CONVAL(1:iend)     ! OUTPUT fixed parameter 1997
            WRITE(linout(nout),1005)
     *                   line(5:19),line(21:34),UNIT,CONVAL(1:iend)
          endif
c
          if(nvers.eq.1999)then
            read(line(2:4),'(i3)')nn
            WRITE(3,1005)line(6:20+mm),line(21+mm:33+mm),UNIT,          ! OUTPUT fixed parameter 1999
     *                   CONVAL(1:iend),nn
            WRITE(linout(nout),1005)
     *                   line(6:20+mm),line(21+mm:33+mm),UNIT,
     *                   CONVAL(1:iend),nn
c
c...additional lines for dependent parameters
            do 46 i=1,npared-1
              if(infpar(i,2).eq.nn)then
                jj=i
47              jj=jj+1
                if(infpar(jj,2).eq.nn)then
                  nout=nout+1
                  ercons(nout)=0.0d0
c
                  call CONFIX(const*conmul(jj),ascld*conmul(jj),        ! <-----
     *                 conval,iend)
c
                  if(iabs(nvib).le.9)then
                    write(3,420)numpar(jj),pnames(jj),UNIT,             ! OUTPUT fixed dependent 
     *                          CONVAL(1:iend),conmul(jj),infpar(jj,2)  ! parameter for nvib<10
                    write(linout(nout),420)
     *                          numpar(jj),pnames(jj),UNIT,
     *                          CONVAL(1:iend),conmul(jj),infpar(jj,2)
                  else
                    write(3,421)numpar(jj),pnames(jj),UNIT,             ! OUTPUT fixed dependent   
     *                          CONVAL(1:iend),conmul(jj),infpar(jj,2)  ! parameter for nvib>9     
                    write(linout(nout),421)
     *                          numpar(jj),pnames(jj),UNIT,
     *                          CONVAL(1:iend),conmul(jj),infpar(jj,2)
                  endif
c
                  if(jj.ge.npared)goto 54
                  goto 47
                else
                  goto 54
                endif
              endif
46          continue
54          continue
          endif
1005  FORMAT(a,2x,A,'/',A,2x,A,t78,i3)
420   FORMAT(i13,3x,A,2x,'/',A,2x,A,T66,'=',F9.5,T77,'*',i3)
421   FORMAT(i15,3x,A,2x,'/',A,2x,A,T66,'=',F9.5,T77,'*',i3)
c
          goto 4
c
c////////////////////////////////////////////////////////////////////////////
c/// end of main input loop /////////////////////////////////////////////////
c////////////////////////////////////////////////////////////////////////////
c
c
5     write(3,'(43x,37(''_'')/42(''_''),
     * ''/ SPFIT output reformatted with PIFORM''/)')
c
      close(3)
      close(2)
      if(lnfile.eq.1)close(4)
c
      nvers=nvers-3*mm/2                                                ! nvers=2002 if mm=-2
      write(*,'(1x/'' SPFIT output version:'',i6///)')nvers
c
      stop 
c
c...error messages
c
c 1358  write(*,1359)
c 1359  format(1x/1x,78(1h-)//' ***** ERROR: '
c      *     'looks like the parameter declaration line in the .PAR file'/
c      * 14x,'is missing the alphanumeric LABEL describing the parameter.'
c      * //14x,
c      *     'This should be at the end of the line, and preceded '/
c      * 14x,'by the / character: an example being  /-deltaJ'/
c      * 14x,'(see the SPFIT documentation on parameter lines).')
c
358   write(*,359)line
359   format(1x//' ***** ERROR reading .FIT output in this line -'/
     *           '                                               |'/
     *  1x,a//)
      close(3)
      close(2)
      stop
c
357   write(*,356)line,ediagn
      write(3,356)line,ediagn
356   format(1x/80('-')//' INPUT ERROR on line: '//1x,a//
     * ' while reading: ',a/80('-')/)
      if(lnfile.eq.1)close(4)
      close(3)
      close(2)
      stop
c
7776  write(*,7775)
7775  format(1x//' ***** ERROR reading the SVIEW_L.INP file'//)
      stop
c
7773  write(*,7772)
7772  format(1x//' ***** ERROR: cannot open the SVIEW_L.INP file'//)
      stop
c
7770  write(*,7769)filin(1:len_trim(filin))
7769  format(1x//' ***** ERROR: cannot open the fitting file:'//1x,a//)
      stop
c
7771  write(*,7768)filin(1:len_trim(filin))
7768  format(1x//
     *  ' ***** ERROR: fitting file as specified in SVIEW_L.INP ',
     *   'is not a .LIN file:'//1x,a//)
c
7787  write(*,7788)filout(1:len_trim(filout))
7788  format(1x//' ***** ERROR: cannot open the specified output file:'
     * //1x,a//)
      stop
c
      stop
      end
C
C_____________________________________________________________________________
c
      subroutine linann(ferror,linapp,napp)
c
c   Reads a line from the .lin file, identifies and writes annotations
c   to the output file
c
c   Deals with multiline annotations concatenated by generation of a .LIN
c   file from within ASFIT
c
c   LINAPP - string to be appended to the output for the current line
c     NAPP - number of characters in the appended string, abbreviated in order
c            not to exceed
c
c
c
      real(8) freq,ferror
      integer lentrm,napp,ncars
      character linlin*600,linapp*80
c
      linapp(1:1)=' '
      napp=1
c
      read(4,'(a)',end=2)linlin
      read(linlin(37:),*,err=6,end=6)freq,ferror
      ncars=lentrm(linlin)
      nloop=1
c
4     nstart=nloop
      do 1 n=nstart,ncars
c
c...annotation line inserted between listed lines
c
        if(linlin(n:n).eq.'!')then
c
          if(n.lt.ncars)then
            if(linlin(n+1:n+1).eq.'!')then
              write(3,'(''!'')')                                        ! OUTPUT of annotation
              goto 1
            endif
          else
            write(3,'(''!'')')                                          ! OUTPUT of annotation
            return
          endif
c
          do 3 nn=n+1,ncars
c
            if(linlin(nn:nn).eq.'!')then
              write(3,'(a)')linlin(n:nn-1)                              ! OUTPUT of annotation
              nloop=nn
              goto 4
            endif
c
            if(linlin(nn:nn).eq.'#')then
              write(3,'(a)')linlin(n:nn-1)                              ! OUTPUT of annotation
              napp=ncars-nn
              if(napp.eq.0)then
                napp=1
                return
              endif
              linapp(1:napp)=linlin(nn+1:ncars)
              goto 5
            endif
c
            if(nn.eq.ncars)then
              write(3,'(a)')linlin(n:nn)                                ! OUTPUT of annotation
              return
            endif

3         continue
c
        endif
c
c...annotation at the end of a line
c
        if(linlin(n:n).eq.'#')then
          napp=ncars-n
          if(napp.eq.0)then
            napp=1
            return
          endif
          linapp(1:napp)=linlin(n+1:ncars)
          goto 5
        endif
c
c...remove leading zeros (if any) from appended comment
c
5       if(napp.gt.1.and.linapp(1:1).eq.' ')then
          napp=napp-1
          linapp(1:napp)=linapp(2:napp+1)
          goto 5
        endif
c
1     continue
c
2     return
c
6     write(*,7)linlin(1:len_trim(linlin))
7     format(1x//
     * ' ERROR on reading from the following line in the .LIN file:'
     * /1x,a//)
      stop
c
      end
C
C_____________________________________________________________________________
c
      SUBROUTINE CONFOR(CONVAL,ERVAL,NDCON,NDEROR,NERD)
C
C   Parameter and error formatting for output
c
c     CONVAL - String containing the parameter value. This is to be
c              input in F format and will be replaced on output by the result
c              string of length extending to the last digit of the error
c     ERVAL  - String containing the error value. This is to be
c              input in F format and will be replaced on output by the result
c              string, which does not contain the decimal point and is meant
c              to be included in brackets
c     NDCON  - The number of digits in the CONVAL string (inclusive of any
c              leading zeros)
c     NDEROR - The number of digits in the ERVAL string (just the significant
c              digits) and is either equal to NERD, or is larger if there
c              are more significant digits than NERD before the decimal point.
c     NERD   - the number of desired error digits, which is to be set on input.
c
c              Both NDCON and NDEROR are generated on output
C
      CHARACTER(27) CONVAL,ERVAL,CONOUT,EROUT
C
      NDEROR=0
      NDNOTZ=0
      ICZERO=0
      erout='???????????'
C
C...Go through digits of parameter value adding those to output buffer while
C   checking at the same time digits of the error value, reacting as
C   necessary.
C   Terminate when either NERD digits in the error value are
C   transferred or, if error has more digits before the decimal
C   point, the decimal point is reached.
C
      conout(1:2)=conval(1:2)
      ndcon=2
      DO 1 N=3,27
        NDCON=NDCON+1
        CONOUT(NDCON:NDCON)=CONVAL(N:N)
C
C...ensure that zero precedes the decimal point and use ICZERO to monitor
C   whether decimal point has been reached
        IF(CONVAL(N:N).EQ.'.')ICZERO=1
        IF(CONVAL(N:N).EQ.'.'.AND.CONVAL(N-1:N-1).EQ.' ')
     *    CONOUT(NDCON-1:NDCON-1)='0'
        IF(CONVAL(N:N).EQ.'.'.AND.CONVAL(N-1:N-1).EQ.'-')THEN
          CONOUT(NDCON-2:NDCON-2)='-'
          CONOUT(NDCON-1:NDCON-1)='0'
        ENDIF
C
C...use NDNOTZ (number of digits not zero) to monitor whether significant
C   digits in parameter value have been reached
        IF(CONVAL(N:N).GE.'1'.AND.CONVAL(N:N).LE.'9')
     *     NDNOTZ=NDNOTZ+1
C
C...do not transfer error digit if it is a leading zero, dot or space
        IF(NDEROR.EQ.0  .AND.  (ERVAL(N:N).EQ.' '.OR.
     *     ERVAL(N:N).EQ.'0'.OR.ERVAL(N:N).EQ.'.') )GOTO 1
C
C...exit if error larger than value and decimal point reached
        IF(NDEROR.GE.NERD .AND. NDNOTZ.GT.0 .AND. ICZERO.EQ.1)GOTO 2
C
C...do not transfer the dot in error value
        IF(ERVAL(N:N).EQ.'.')GOTO 1
C
C...transfer error digits until NERD or, if more, the first significant
C   digit in value is reached
        NDEROR=NDEROR+1
        EROUT(NDEROR:NDEROR)=ERVAL(N:N)
        IF(NDEROR.GE.NERD .AND. NDNOTZ.GT.0 .AND. ICZERO.EQ.1)GOTO 2
1     CONTINUE
c
c...output string with fitted value (rounding is to be carried out externally)
c
2     CONVAL(1:NDCON)=CONOUT(1:NDCON)
c
c...output string with error (rounded if necessary)
c
      if(nderor.gt.0)then
c       write(*,'(1x,2a,5x,a)')                                         DEBUG
c    *    'ERROR: ',erval,erout(1:nderor)                               DEBUG
c
        if(erval(ndcon+1:ndcon+1).eq.'5'.or.
     *     erval(ndcon+1:ndcon+1).eq.'6'.or.
     *     erval(ndcon+1:ndcon+1).eq.'7'.or.
     *     erval(ndcon+1:ndcon+1).eq.'8'.or.
     *     erval(ndcon+1:ndcon+1).eq.'9')then
          read(erout(1:nderor),*)ieror
          net=int(dlog10(dble(ieror)))                                  ! Fortran2018
          ieror=ieror+1
          net1=int(dlog10(dble(ieror)))                                 ! Fortran2018
          if(net1-net.gt.0)nderor=nderor+1
          write(erout,'(i12)')ieror
          erval(1:nderor)=erout(12-nderor+1:12)
        else
              ERVAL(1:NDEROR)=EROUT(1:NDEROR)
        endif
      endif
C
      RETURN
      END
C_____________________________________________________________________________
c
c
      subroutine confix(const,ascld,conval,iend)
c
C   Fixed parameter formatting for output
c
      implicit real(8) (a-h,o-z)
      character conval*27
C
      if(dabs(const).le.1.d-19)ascld=0.0d0
      IF(ASCLD.NE.0.0D0)ASCLD=ASCLD+DMOD(ASCLD,1.0D-15*ASCLD)
      WRITE(CONVAL,'(F27.16)')ASCLD
c
c...deal with leading zero
      IF(ASCLD.EQ.0.0D0)CONVAL='         0.0               '
      IF(CONVAL(10:10).EQ.' ')CONVAL(10:10)='0'
      IF(CONVAL(10:10).EQ.'-')THEN
        CONVAL(10:10)='0'
        CONVAL(9:9)='-'
      ENDIF
c
c...set leading square bracket
      do 2115 m=1,27
        if(CONVAL(M:M).NE.' ')GOTO 2116
2115  continue
2116  if(m.gt.8)then
        conval(8:8)='['
      else if(m.gt.1.and.m.le.8)then
        conval(m-1:m-1)='['
      endif
c
c...blank at the end so that number processed is within 15 digit accuracy
      if(ascld.ne.0.0d0)then
        mmm=int(alog10(real(abs(ascld))))
        if(mmm.ge.-1)mmm=mmm+1
        do 2117 m=27,27-mmm,-1
          conval(m:m)='0'
2117    continue
      endif
c
c...find last non-zero digit
      DO 1114 M=27,1,-1
        IF(CONVAL(M:M).NE.'0'.AND.CONVAL(M:M).NE.' ')GOTO 1115
        IF(CONVAL(M:M).EQ.'0')CONVAL(M:M)=' '
1114  CONTINUE
C
C...terminating square bracket
C
1115  iend=m+1
      if(iend.gt.27)iend=27
      conval(iend:iend)=']'
c
      return
      end
C_____________________________________________________________________________
c
c
      subroutine corelm(ncon,nout)
      parameter (maxcon=6000,cormax=0.995)
c
c...Reformat and write out the correlation matrix
c
c    NCON   - number of independent fitted parameters
c    NOUT   - number of all parameters inclusive of the fixed ones, but excluding
c             the dependent ones
c    INFITC - fitted parameter running number (from 1 to NCON)
c    IDPAR  - fitted parameter SPFIT numerical identifier
c    CNAMES - fitted parameter alphanumeric name
c
      real(4) cmat(maxcon,maxcon)
      CHARACTER line*128,cnames(maxcon)*10
      integer infitc(0:maxcon)
      integer(8) idpar(maxcon)
      common /names/cnames,idpar,infitc
c
c...loop to read lines containing correlation coefficients
c
      nread=0
3     read(2,'(a128)',err=2,end=2)line                                  ! INPUT correlation coefficients
      ilst=1
      ilen=16
      do 4 n=1,8
        read(line(ilst:ilen),1,err=2,end=2)i,j,cc
        if(i.eq.0.or.j.eq.0)goto 2
        cmat(i,j)=cc
        ilst=ilst+16
        ilen=ilen+16
        nread=nread+1
4     continue
1     format(2i3,f10.6)
      GOTO 3
c
c..Write out correlation matrix (lower triangle only), using code adapted
c                                                          from ASFIT.FOR
C
2     if(nread.eq.0)return
      do 200 n=1,nout
        cmat(n,n)=1.d0
200   continue
c
      WRITE(3,202)
202   FORMAT(/' CORRELATION COEFFICIENTS, C.ij:')
      NCORCO=0
      CORCAV=0.0D0
      CCSUM=0.0D0
      M=1
c
c...main loop, each cycle writing successive 8 columns
c
305   MM=M+7
      IF(MM.GT.ncon)MM=ncon
      WRITE(3,301)
      WRITE(3,230)(cnames(infitc(L)),L=M,MM)                            ! OUTPUT correlation header
230   FORMAT(10x,8(1X,A8))
      WRITE(3,301)
301   format(1x)
c
      DO 302 N=M,ncon
        LLLL=MM
        IF(LLLL.GT.N)LLLL=N
c
c___identify and ignore horizontal lines containing only zero coefficients,
c   which are present for fixed parameters
        nonzer=0
        do 3050 L=M,LLLL
          if(abs(cmat(infitc(N),infitc(L))).lt.0.0001)goto 3050
          nonzer=1
3050    continue
c
        if(nonzer.eq.1)WRITE(3,303)cnames(infitc(N)),                   ! OUTPUT correlation matrix
     *             (cmat(infitc(N),infitc(L)),L=M,LLLL)
c
        DO 3030 L=M,LLLL
          IF(L.NE.N)THEN
            NCORCO=NCORCO+1
            CORCAV=CORCAV+ABS(cmat(infitc(N),infitc(L)))
            CCSUM=CCSUM+cmat(infitc(N),infitc(L))
          ENDIF
3030    CONTINUE
c
302   CONTINUE
c
303   FORMAT(A10,f8.4,7(F9.4))
c
      IF(MM.GE.ncon)THEN
        GOTO 3031
      ELSE
        M=M+8
        GOTO 305
      ENDIF
c
c...Write mean values of correlation coefficients
c
3031  IF(NCORCO.NE.0)THEN
        WRITE(3,3032)CORCAV/NCORCO,CCSUM/NCORCO
3032    FORMAT(1X/' Mean value of |C.ij|, i.ne.j =',
     *      F9.4/
     *            ' Mean value of  C.ij,  i.ne.j =',
     *      F9.4/)
      ENDIF
c
c...Write out list of highest correlations
c
      nbadc=0
      do 4150 n=2,nout                                                  ! Fortran2018
        do 3150 m=1,n-1
          if(abs(cmat(n,m)).lt.cormax)goto 3150
          nbadc=nbadc+1
          if(nbadc.eq.1)then
            write(3,3152)cormax
3152        format(1x/
     *       ' Worst correlations, with absolute value greater than',
     *       f7.4,':'/)
          endif
          write(3,3151)idpar(n),cnames(n),idpar(m),cnames(m),cmat(n,m)
3151      format(i12,2x,a,'<->',i12,2x,a,f12.6)
3150    continue
4150  continue                                                          ! Fortran2018
c
      if(nbadc.gt.0)then
        write(3,'(1x)')
      else
        write(3,3154)cormax
3154    format(1x/
     *      ' No correlations with absolute value greater than', f7.4/)
      endif
c
      return
      end
c
c_____________________________________________________________________________
C
C  Actual length of a string (equivalent to LEN_TRIM)
C
      integer function lentrm(carg)
      character carg*(*)
      integer nn,n
c
      nn=len(carg)
      do 1 n=nn,1,-1
       if(carg(n:n).gt.' ')goto 2
1     continue
2     lentrm=n
      if(lentrm.lt.1)lentrm=1
c
      return
      end
C
C____________________________________________________________________________
C
      SUBROUTINE WORSTL(NLIN,nmcolon)
c
c...Sort and list worst fitted lines
c
      PARAMETER (maxlin=100000,lastl=50)
C
      COMMON /SORTCC/OMINC,IPT
      common /lbuff/linbuf
      INTEGER   IPT(maxlin)
      REAL(8)   OMINC(maxlin)
      CHARACTER LINBUF(maxlin)*130
C
      CALL SORTC(1,NLIN)                                                ! <-----
      write(3,1)
      write(*,1)
1     Format(1x/' Worst fitted lines (obs-calc/error):'/)
c
      nst=nlin-lastl+1
      if(nst.le.0)nst=1
      do 2 n=nlin,nst,-4
        nlst=n-3
        if(nlst.lt.nst)nlst=nst
        write(3,4)(ipt(nn),ominc(nn),nn=n,nlst,-1)                      ! OUTPUT of 50 worst lines
        write(*,4)(ipt(nn),ominc(nn),nn=n,nlst,-1)
2     continue
4     format(1x,4(i5,':',f7.1,6x))
c
c...usually only the last four digits of line numbers are stored in LINBUF
c   so that actual line numbers are taken from IPT
C
      write(3,'(1x)')
      do 5 n=nlin,nlin-9,-1
        if(ipt(n).ne.0)
     *    write(3,'(i6,a)')ipt(n),                                      ! OUTPUT of 10 worst lines
     *                linbuf(ipt(n))(nmcolon+1:len_trim(linbuf(ipt(n))))
5     continue
c
      RETURN
      END
C____________________________________________________________________________
C
      SUBROUTINE SORTC(N,M)
      PARAMETER (maxlin=100000)
C
      COMMON /SORTCC/WK,IPT
      INTEGER   IPT(maxlin)
      REAL(8)   WK(maxlin),EE
C
C ... This routine sorts the ABSOLUTE values of the quantities in vector WK in
C     ascending order
C     of magnitude and also accordingly rearranges vector IPT of pointers
C     to original positions of sorted quantities
C
      DO 101 I=N,M-1
        J=I
106     J=J+1
c       IF(abs(WK(J))-abs(WK(I)))103,104,104
        IF(abs(WK(J))-abs(WK(I)).ge.0.0d0)goto 104                      ! Fortran2018
        EE=WK(I)
        WK(I)=WK(J)
        WK(J)=EE
        K=IPT(I)
        IPT(I)=IPT(J)
        IPT(J)=K
104     IF(J.EQ.M)GOTO 101
        GOTO 106
101   CONTINUE
C
      RETURN
      END
C____________________________________________________________________________
C
      subroutine ident(line,dipind,pqrind,nbreak,lshift,nqns)
C
c      Carry out transition type identification:
C      del_Ka,del_Kc = eo  mua
C                      oo  mub
C                      oe  muc

      implicit real(8) (a-h,o-z)
      character line*155,dipind*2,pqrind*2
c
        pqrind='? '
        dipind=' ?'
c
        read(line(nbreak-3*(nqns-3)-9+lshift:
     *            nbreak-3*(nqns-3)-7+lshift),'(i3)',err=50)jup
        read(line(nbreak-3*(nqns-3)-6+lshift:
     *            nbreak-3*(nqns-3)-4+lshift),'(i3)',err=50)kaup
        read(line(nbreak-3*(nqns-3)-3+lshift:
     *            nbreak-3*(nqns-3)-1+lshift),'(i3)',err=50)kcup
c
        read(line(nbreak+lshift:
     *            nbreak+lshift+2),'(i3)',err=50)jlow
        read(line(nbreak+lshift+3:
     *            nbreak+lshift+5),'(i3)',err=50)kalow
        read(line(nbreak+lshift+6:
     *            nbreak+lshift+8),'(i3)',err=50)kclow
c
        idelj=jup-jlow
        idelka=kaup-kalow
        idelkc=kcup-kclow
c
        if(idelj.eq.-1)pqrind='P '
        if(idelj.eq. 0)pqrind='Q '
        if(idelj.eq. 1)pqrind='R '
c
        ieoka=iabs(idelka-(idelka/2)*2)                                 ! even/odd Ka
        ieokc=iabs(idelkc-(idelkc/2)*2)                                 ! even/odd Kc
c
        if(ieoka.eq.0.and.ieokc.eq.1)dipind=' a'
        if(ieoka.eq.1.and.ieokc.eq.1)dipind=' b'
        if(ieoka.eq.1.and.ieokc.eq.0)dipind=' c'
c
50    return
      end
C_____________________________________________________________________________
C
C   Modules used by PIFORM:
C_____________________________________________________________________________
C
C   linann    - transfer of annotations from the .LIN line to the output
C   confor    - fitted parameter and error formatting for output
c   confix    - fixed parameter formatting for output
c   corelm    - reformatting and output of the correlation matrix
c   lentrm    - LEN_TRIM replacement
c   worstl    - processsing and listing of worst fitted lines
c   sortc     - sorting of worst fitted lines
c
c   Search for the string "/ OUTPUT" to locate main output lines
C_____________________________________________________________________________
C_____________________________________________________________________________
c



c H2ClCCF3 = HCFC-133a  (FTMW v=0, MMW v=1)              Mon Jun 01 12:40:28 2015
cLINES REQUESTED= 2270 NUMBER OF PARAMETERS= 57 NUMBER OF ITERATIONS= 13
c  MARQUARDT PARAMETER =0.0000E+000 max (OBS-CALC)/ERROR =5.0000E+002
c                              PARAMETERS - A.PRIORI ERROR
c     1      1         10000  5.3328457164677E+003   1.000000E+000 A
c     2      1        -10011  5.3328457164677E+003        1.000000 A
c     1      1         10000   5.3328457164677E+03    1.000000E+00 A
c
c
c
c H2ClCCF3 = HCFC-133a  (FTMW v=0, MMW v=1)              Mon Jun  1 13:23:41 2015
cLINES REQUESTED= 2270 NUMBER OF PARAMETERS= 57 NUMBER OF ITERATIONS= 13
c  MARQUARDT PARAMETER = 0.0000E+00 max (OBS-CALC)/ERROR =5.0000E+02
c                              PARAMETERS - A.PRIORI ERROR
c     2      1        -10011   5.3328457164677E+03        1.000000 A
c     3      1        -10022   5.3328457164677E+03        1.000000 A
c     4      2         20000   1.8033987618569E+03    1.000000E+00 B



c     1      1         10000   5.3328457164677E+03    1.000000E+00 A





c       write(*,*)numpar(npared)                                        debug

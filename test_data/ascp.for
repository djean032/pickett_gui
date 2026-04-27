C+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
C
C     ASCP - Diagrams of predictions from Pickett's program SPCAT and 
C            from ZK's ASROT
C
C+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
C
C     This program produces a fully scalable/scrollable stick diagram of
C     spectral predictions made with program ASROT.
C     The program can also display predictions from Pickett's program SPCAT
C       1/ by reading .CAT files directly
C       2/ by reading output from program PISORT, which allows conversion of
C          .OUT files with modification of temperature, frequency sorting etc.
C
C     Principal features:
C
C     - up to MAXFIL data sets can be read in under manual or batch type
C       control
C     - concatenation of data from several files into one file is allowed,
C       as well as reading in a mixture of .ASR and .CAT files
C     - altogether up to MAXLIN lines may be read in
C     - display can be: sticks, simulated spectrum or sticks+spectrum
C     - numerous highlighting options are available to distinguish
C       line subsets of interest
C     - filtering is posssible to exclude lines outside frequency limits
C       or below an intensity cutoff
C     - data from different files may be plotted in different line
C       styles/colours and intensities may be scaled by separate
C       population factors
C     - each transition is fully annotated, and annotations are automatically
C       displayed when the transition is selected with the cursor
C     - various types of additonal information on loaded transitions and
C       on-line help are available
C     - if LIST file produced by the SLIST program is available in the same
C       directory as other input files then frequency ranges and names of 
C       measured spectra are displayed
C     - output of current display for the GLE program can be produced
C       (files xxx.GLE and xxxn.DAT) which gives a route to publication
C       quality PostScript printouts
C
C     ASC/ASCP have been used in many investigations involving overlapped
C     vibrational satellites, different isotopomers and complex nuclear
C     quadrupole structure.
C
C     Publication quality diagrams can be obtained by direct GLE output.
C     Additional flexibility is provided by the filtering option on input 
C     and the postprocessing program ASRGLE.
C
C     Stick diagrams produced in this way can be found in:
C         JMS 184,150(1997) - CHF2Cl,
C         JMS 189,228(1998) - CH3CCl3,
C         CPL 276,202(1997) - N2...HCl and
C         JCP 109,10263(1998) - CHCl=CHCl2
C
C     Summaries of applications and brief discussions of ASCP are given in the
C     two papers listed below, which serve as citations of the use of
C     this program:
C
C     Z.Kisiel, E.Bialkowska-Jaworska, L.Pszczolkowski
C                         J.Chem.Phys. 109,10263-10272(1998).
C     Z.Kisiel, E.Bialkowska-Jaworska, L.Pszczolkowski
C                         J.Mol.Spectrosc. 199,5-12(2000)
C
C
C     Version 20b.II.2004                          ----- Zbigniew KISIEL -----
C
C                          __________________________________________________
C                         | Institute of Physics, Polish Academy of Sciences |
C                         | Al.Lotnikow 32/46, Warszawa, POLAND              |
C                         |                             kisiel@ifpan.edu.pl  |
C                         |     http://info.ifpan.edu.pl/~kisiel/prospe.htm  |
C_________________________/--------------------------------------------------
C
C
C     ASCP is a derivative of ASC which in turn started as ASPEC and
C     used only the six asymmetric rotor quantum numbers per transition.
C
C  Modification history:
C
C     ca.86:  created on HP-150 (XT-compatible) for screen display and printout
C             on paper ribbon using the HP Thinkjet - the first HP inkjet
C             printer
C      2.92:  change from mono MSF5.0 version to colour (routine COLBEE by
C             L.Pszczolkowski)
C   5.10.95:  selection of strongest line for first time display of overlaps,
C             free format input of frequency limits
C  30.01.96:  addition of CLOSE(2) statement
C  23.10.96:  patch for input from file converted from SPCAT output
C   7.01.97:  more fixes for operation on .ASR from .OUT files
C  25.03.97:  echo file
C   2.04.97:  default line colour and modified ',' marker option
C  10.01.98:  creation of ASCP
C  23.02.98:  modification to also read ASROT files
C  16.12.98:  use of ANSI.SYS scrapped + port to MSFPS1.0 graphics
C  16.01.99:  flexible frequency labels
C   8.08.99:  readable input control file
C   5.09.99:  graphics compatibility taken up to the level in V32
C   9.08.00:  safeguards against crashing out in graphics mode on input
C  24.08.00:  various incremental modifications + direct GLE output
C  30.05.01:  conversion to CVF6.5 graphics and major overhaul
C  24.10.01:  several small mods
C   9.02.02:  configuration file for graphics + debugging
C  27.12.02:  switch to QWIN graphics and an optional half-height screen 
C   4.03.03:  simulation of spectral contour
C  19.03.03:  information on recorded spectra if LIST file is available,
C             use of own instead of WIN32 linestyles
C   3.06.03:  enhancements to contour simulation
C  14.08.03:  sorting out Window frame-size compatibility problems
C  20.02.04:  data refresh option
C
C
C-----------------------------------------------------------------------------
C     I N S T A L L A T I O N:
C-----------------------------------------------------------------------------
C
C     1/ place ASCP.EXE and ASCP.CFG in directory C:\ROT
C     2/ using Windows Explorer send a shortcut to ASCP to the desktop
C     3/ add C:\ROT to the PATH if it is planned to launch from the command
C        prompt
C
C-----------------------------------------------------------------------------
C     A S C P   A N D   W I N D O W S:
C-----------------------------------------------------------------------------
C
C     In Win95/98 it is best to launch ASCP from the command line, after having
C     moved to the directory which contains the required files.  The current
C     directory is assumed to be the default directory.
C
C     In Win2000, irrespective of launch type, the system remembers the last
C     directory in which ASCP was used and assumes it as default.  If this
C     directory is no longer to be worked on then it is necessary to
C     navigate to the required directory using the FileSelect window.
C
C     Drag and drop operation is possible on all three input file types, ie.
C     .ASR, .CAT and .INP.  The file can be dragged onto the ASCP icon and,
C     once file type option is set as necessary, the dragged file will
C     be read in and processed as required.
C
C     Irrespective of the system the program assumes that the default
C     directory for file names specified in the batch input .INP file is the
C     directory containing that file.  The ECHO.ASC file, if specified, and
C     the gle files will also end up in this directory.
C
C
C-----------------------------------------------------------------------------
C     U S E   O F   C O L O U R:
C-----------------------------------------------------------------------------
C
C     Colour is used extensively to better distinguish
C     band types and to mark transitions of interest.  Many of the colours
C     are created by the program in its own colour pallette so
C     its intended appearance should not change much with the colour depth
C     setting of the video display (which should be at least 256 colours),
C
C     Widely differing colours are
C     used to differentiate between a-,b- and c-type transitions, whereas
C     for a given transition type different shades of the same colour
C     differentiate between P- or R- and Q-type transitions.
C
C     Transitions can be highlighted on the basis of:
C     1/ the same value of selected lower state quantum number
C     2/ the same data set
C     3/ the same transition type
C     all of the above can be for the current or all data sets
C
C     Several colour schemes of background/highlighting colours are available
C     for use as required.
C
C
C-----------------------------------------------------------------------------
C     B A T C H   I N P U T:
C-----------------------------------------------------------------------------
C
C     Batch input is controlled by entries in a special control file
C     (recommended extension .INP) with the following contents:
C
C  ---- first column           ---- column 29
C |                           |
C          filtering (1/0):   1                                <- first line
C         frequency limits:   FMIN,FMAX
C         intensity cutoff:   SLIMIT
C          echo file (1/0):   0
C ------------------------------------------------
C        parent data file :   PARENT.ASR
C more data (1), end (0)  :   1
C ------------------------------------------------
C name of data file       :   STATEA.ASR
C intensity rel. to parent:   RELINT
C line code (1-10)        :   LSTYLE
C more data (1), end (0)  :   1
C ------------------------------------------------
C .
C . repeat as necessary and terminate input for the last data file as below
C .
C more data (1), end (0)  :   0
C ------------------------------------------------
C
C
C     It is best to use the SAMPLE.INP file from the PROSPE site as a template,
C     and then:
C
C   - Fill in appropriate numerical values for FMIN, FMAX, SLIMIT,RELINT
C     (floating point) and LSTYLE (integer)
C   - PARENT.ASR and STATEA.ASR are specimen names of data files to be read
C     in, these can also be .CAT files
C   - RELINT is relative intensity to be used for scaling data relative
C     to that in file PARENT.ASR
C   - LSTYLE is line style to be used for plotting scaled data file (1-10)
C   - if filtering is set to zero then all lines from data files are read in
C     and the second,third,fourth control lines are ignored
C   - FSTART,FEND are frequency limits
C   - SLIMIT is the intensity cutoff, ie lower limit of intensity for
C     lines to be read in
C   - the echo file option allows generation of file ECHO.ASC containing
C     all lines from input .ASR or .CAT files which satisfy the sort crtiteria.
C     Note that what is echoed are complete unmodified lines from the input 
C     files.
C
C
C-----------------------------------------------------------------------------
C    C O M P I L A T I O N:
C-----------------------------------------------------------------------------
C
C    This version will only compile satisfactorily with
C    Compaq Visual Fortran 6.50 (and possibly with not too distant earlier
C    versions of Microsoft Powerstation Fortran)
C
C    Compilation is now to be for QWIN graphics - this necessitates explicit
C    programming out of several unnecessary frills, but results in smoother
C    launch of the program than is possible with the STANDARD graphics as used 
C    previously.
C
C-------------------------------- 
C    Command line compilation:
C-------------------------------- 
C
C    Simplest compilation for the local machine:
C
C        df -static -libs=qwin -fpscomp:filesfromcmd ascp.for
C
C    Compilation for any PENTIUM:
C
C        df -static -libs=qwin -arch:pn1 -fpscomp:filesfromcmd ascp.for
C
C    Optimised compilation for Pentium III:
C
C        df -static -libs=qwin -fast -architecture:pn3 -tune:pn3
C                                 -fpscomp:filesfromcmd ascp.for
C
C-------------------------------- 
C    Visual Studio compilation:
C-------------------------------- 
C
C    FORTRAN:  /compile_only /fpscomp:filesfromcmd
C              /libs:qwin /nologo /nopdbfile /optimize:3 /traceback /tune:pn1 
C              /architecture:pn1 /static
C
C    LINK:     kernel32.lib /nologo /subsystem:windows /pdb:none 
C              /machine:IX86 /out:"Debug/ASCP.exe" 
C
C
C-----------------------------------------------------------------------------
C     K E Y   V A R I A B L E S:
C-----------------------------------------------------------------------------
C
C        S(i) - intensity of line i
C      SET(i) - number of data set to which the line belongs
C       NLSET - the number of data sets
C NQ(i,1..12) - quantum numbers of line i in the order
C               J',K-1',K+1',J'',K-1'',K+1'',n1',n2',n3',n1'',n2'',n3''
C   NCOLOR(i) - colour for plotting line i (including the effect of
C               of highlighting)
C   LCOLOR(i) - the reference colour of line i
C      LST(i) - linestyle for plotting line i
C    DIPOL(i) - dipole type for transition i; 'a', 'b' or 'c'
C        M(i) - indication of whether the line is an unresolved doublet; 'D'
C      NLINES - number of lines
C        F(j) - frequency of j'th line in order of frequency
C     LNUM(j) - pointer i in S,SET,etc. to information on j'th line in order of
C               frequency from among all data sets.  NOTE that only LNUM
C               and F are altered on sorting
C   SETNAM(N) - names of files containing the various data sets
C    SETNM(N) - as above but without any path
C  INFSET(N,i)- information on data sets where
C              i=1 relative intensity, in REAL*4 form via an EQUIVALENCEd
C                  array RELATI()
C              i=2 linestyle
C              i=3 number of lines
C
C
C===========================================================================
C
C...Initialization commands for graphics.  The three structured
C   variables store current values of:
C     curpos.row and curpos.col - cursor coordinates (INTEGER*2)
C     ixy.xcoord and ixy.ycoord - pixel coordinates (INTEGER*2)
C     wxy.wx and wxy.wy - window coordinates (REAL*8)
C
      USE DFLIB
c
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
C_____________________________________________________________________________
c
      PARAMETER (MAXLIN=100000,linmax=maxlin-2,maxfil=20,maxspe=500)
      PARAMETER (ntextc=0, ntextb=7)
c
      CHARACTER L(80),DIPOL(MAXLIN),M(MAXLIN),line*80,numbuf*40
      CHARACTER FILNAM*50,FILCON*50,CDUMMY,gener*50,errmes*45,
     *          filech*60
      CHARACTER SETNAM(maxfil)*30,setnm(maxfil)*20,spenam(maxspe)*12,
     *          namspe*12
      INTEGER*1 SET(MAXLIN),LST(MAXLIN)
      REAL*4 S(MAXLIN),SMAX,SLIMIT,relati(maxfil),ELOW(maxlin)
      REAL*8 F(MAXLIN),FMIN,FMAX,FOLD,FSTART,FEND,
     *          fa,fb,fspa(maxspe),fspb(maxspe)
      INTEGER*4 LNUM(MAXLIN),INFSET(maxfil,3),dummy4
      INTEGER*2 NQ(MAXLIN,12)
      INTEGER*1 NCOLOR(MAXLIN),LCOLOR(MAXLIN)
      EQUIVALENCE (L(1),LINE)
      COMMON /FRBLK/F/SBLK/FMIN,FMAX,ELOW,S,SMAX,NLINES
      COMMON /ORIGLN/SET,LST,NLSET,NCOLOR,LCOLOR
      COMMON /LNUMS/LNUM/DOUBL/M
      COMMON /QNUMS/NQ
      COMMON /DIP/DIPOL
      COMMON /SETINF/INFSET,SETNAM,setnm,gener
      COMMON /SPECS/fspa,fspb,spenam,nsp
      COMMON /limits/wxy,maxx,maxy,linofs,curpos,ixy,
     * mymode,myrows,mycols
      INTEGER*2 maxx,maxy,linofs,mymode,myrows,mycols
      equivalence (relati(1),infset(1,1))
C
      ISORT=0
      FOLD=0.D0
      RELINT=1.0
      NLSET=-1
      NLINES=0
      NLST=1
      SMAX=1.E-12
      FMIN=1.D30
      FMAX=0.D0
      NLAST=0
      limit=0
      irefr=0
C
      call startg(iconf)                                                <-----
      dummy4=passdirkeysqq(.true.)
c
C...HEADER
C
      numfonts = INITIALIZEFONTS ( )
      fontnum = SETFONT ('t''Arial''h75w25ei')
      dummy4=setbkcolor(ntextb)
      call clearscreen($gclearscreen)
c
      NBOTL=120
      dummy=setcolor(15)
      CALL MOVETO (INT2( 0), INT2(NBOTL), ixy)
      dummy=lineto(INT2( maxx), INT2(NBOTL))
      CALL MOVETO (INT2( 0), INT2(0), ixy)
      dummy=lineto(INT2( maxx), INT2(0))
      dummy=setcolor(8)
      dummy=floodfill(1,1,15)
c
      nvert=(NBOTL-75)/2
      nhor=(maxx-770)/2
      if(nhor.lt.10)nhor=10
      dummy=setcolor(11)
      CALL MOVETO (INT2(nhor), INT2(nvert), ixy)
      CALL OUTGTEXT('ASCP - Viewer for Stick Spectra')
      dummy=setcolor(9)
      CALL MOVETO (INT2(nhor+1), INT2(nvert+1), ixy)
      CALL OUTGTEXT('ASCP - Viewer for Stick Spectra')
      dummy=setcolor(1)
      CALL MOVETO (INT2(nhor+2), INT2(nvert+2), ixy)
      CALL OUTGTEXT('ASCP - Viewer for Stick Spectra')
c
      dummy=setcolor(15)
      CALL MOVETO (INT2(    0), INT2(NBOTL+ 32), ixy)
      dummy=lineto(INT2( maxx), INT2(NBOTL+ 32))
      dummy=setcolor(8)
      dummy=floodfill(1,INT2(NBOTL+30),15)
c
      dummy=setcolor(0)
      CALL MOVETO (INT2(    0), INT2(NBOTL+ 32), ixy)
      dummy=lineto(INT2( maxx), INT2(NBOTL+ 32))
      dummy=setcolor(7)
      CALL MOVETO (INT2(    0), INT2(NBOTL+  1), ixy)
      dummy=lineto(INT2( maxx), INT2(NBOTL+  1))    
c
      fontnum = SETFONT ('t''Arial''h20w10')
      dummy=setcolor( 0)
      CALL MOVETO (INT2( 11), INT2(NBOTL+ 7), ixy)
      CALL OUTGTEXT('version 20b.II.2004')
      CALL MOVETO (INT2( maxx-169), INT2(NBOTL+ 7), ixy)
      CALL OUTGTEXT('Zbigniew KISIEL')
      dummy=setcolor(15)
      CALL MOVETO (INT2( 10), INT2(NBOTL+ 6), ixy)
      CALL OUTGTEXT('version 20b.II.2004')
      CALL MOVETO (INT2( maxx-170), INT2(NBOTL+ 6), ixy)
      CALL OUTGTEXT('Zbigniew KISIEL')
c
      nrlin=nint(real(NBOTL+32)/(real(maxy)/real(myrows)))+2
      call settextposition(nrlin,67,curpos)
      dummy=settextcolor(ntextc)
      write(*,'(i7,'' lines'',$)')maxlin
c
C...Warn of missing config file
C
70    call settextposition(11,1,curpos)
      if(iconf.eq.0)then
        dummy=setcolor(12)
        fontnum = SETFONT ('t''Arial''h18w9e')
        CALL MOVETO (INT2(100), INT2(200), ixy)
        CALL OUTGTEXT(
     *    'Configuration file C:\ROT\ASCP.CFG was not found:')
        CALL MOVETO (INT2(250), INT2(220), ixy)
        fontnum = SETFONT ('t''Arial''h18w9i')
        CALL OUTGTEXT(
     *    'default sized window of 800x540 pixels will be used')
        call settextposition(15,1,curpos)
      endif
C
C...Determine data input mode
C
      dummy=settextcolor(ntextc)
      dummy4=setbkcolor(ntextb)
      write(*,112)
112   FORMAT(1x/10x,'TYPE THE NUMBER OF THE DESIRED OPTION:'//
     *  14x,'1  Direct input from .ASR files'/
     *  14x,'2  Direct input from .CAT files'/
     *  14x,'3  Batch input'//10x,'... ',$)
      dummy=displaycursor($gcursoron)
72    read(*,*,err=71)iflag
      if(iflag.lt.1.or.iflag.gt.3)goto 71
      goto 73
c
71    call settextposition(18,10,curpos)
      write(*,'(50(1H ))')
      call settextposition(18,10,curpos)
      write(*,'(''... '',$)')
      goto 72
c
c...batch input
c
73    if(iflag.eq.3)then
        if(irefr.eq.1)then
          call clearscreen($gclearscreen)
          goto 75
        endif
        CALL SETMESSAGEQQ(
     *    " INP Files (*.inp), *.inp;"//
     *    " All Files (*.*), *.*",
     *                  QWIN$MSG_FILEOPENDLG)
74      call clearscreen($gclearscreen)
        WRITE(*,111)
111     FORMAT(1x//10x,'TYPE ONE OF:'//
     * 14x,'Name of data file,'/
     * 14x,'ENTER for the SelectFile box'//10X,'... ',$)
        READ(*,3,ERR=74)FILCON
75      OPEN(4,file=FILCON,ERR=74,status='old')
        if(irefr.ne.1)then
          if(filcon.eq.'')then
            inquire(4,name=filcon)
            do 115 n=len_trim(filcon),1,-1
              if(filcon(n:n).eq.'\')goto 116
115         continue
116         if(n.gt.1)gener=filcon(1:n)
          else
            gener=''
          endif
        endif
        read(4,'(a)',err=119)line
        if(line(10:25).ne.'filtering (1/0):')goto 119
        backspace(4)
        goto 2
119     dummy=settextcolor(15)
        dummy4=setbkcolor(12)
        write(*,125)
125     format(1x//'***** ERROR: this doesn''t look like a .INP file')
        dummy=settextcolor(ntextc)
        dummy4=setbkcolor(ntextb)
        write(*,120)filcon,line(1:53)
120     format(1x/
     *   '  ASCP expects to find:__         filtering (1/0):'//
     *   'but first line of file:__',a/
     *   '              contains:__',a//)
        pause '      Press ENTER to continue and exit ASCP'
        stop
      endif
C
C- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C   This block is repeated when there is more than one data file
C
C...determine name of data file
C
2     if(iflag.eq.1)then
        CALL SETMESSAGEQQ(
     *    " ASROT compatible files (*.asr), *.asr;"//
     *    " All Files (*.*), *.*",
     *                  QWIN$MSG_FILEOPENDLG)
22      call clearscreen($gclearscreen)
        WRITE(*,111)
        READ(*,3,ERR=22)FILNAM
3       FORMAT(A)
      endif
c
      if(iflag.eq.2)then
        CALL SETMESSAGEQQ(
     *    " Pickett CAT Files (*.cat), *.cat;"//
     *    " All Files (*.*), *.*",
     *                  QWIN$MSG_FILEOPENDLG)
23      call clearscreen($gclearscreen)
        WRITE(*,111)
        READ(*,3,ERR=23)FILNAM
      endif
c
      if(iflag.eq.3)then
        write(*,'(1x//1x,a,$)')'Batch input from '
        dummy=settextcolor(15)
        dummy4=setbkcolor(1)
        write(*,'(a/)')filcon(1:len_trim(filcon))
        dummy=settextcolor(ntextc)
        dummy4=setbkcolor(ntextb)
        IF(NLSET.EQ.-1)THEN
          errmes='reading filtering parameter LIMIT'
          read(4,'(a)',err=500,end=501)line
          backspace(4)
          READ(4,300,err=500,end=501)LIMIT
c
          errmes='reading frequency limits FSTART,FEND'
          read(4,'(a)',err=500,end=501)line
          backspace(4)
          READ(4,301,err=500,end=501)FSTART,FEND
c
          errmes='reading intensity cutoff SLIMIT'
          read(4,'(a)',err=500,end=501)line
          backspace(4)
          READ(4,301,err=500,end=501)SLIMIT
c
          errmes='reading echo file flag IECHO'
          read(4,'(a)',err=500,end=501)line
          backspace(4)
          READ(4,300,err=500,end=501)IECHO
c
          if(IECHO.eq.1)then
            filech=gener(1:len_trim(gener))//'echo.asc'
            open(5,file=filech,status='unknown')
          endif
          nlset=0
        ENDIF
300     FORMAT(28X,I5)
301     FORMAT(28X,2F20.10)
302     FORMAT(A)
c
        errmes='skipping a spacing line'
        read(4,'(a)',err=500,end=501)line
        backspace(4)
        READ(4,302,end=500)CDUMMY
c
        errmes='reading file name FILNAM'
        read(4,'(a)',err=500,end=501)line
        backspace(4)
        READ(4,303,err=500,end=501)FILNAM
303     FORMAT(28X,A)
        filnam=gener(1:len_trim(gener))//filnam(1:len_trim(filnam))
        write(*,'(1x,a,$)')'    Reading from '
        dummy=settextcolor(12)
        write(*,'(a)')filnam(1:len_trim(filnam))
        dummy=settextcolor(ntextc)
      endif
c
76    OPEN(2,FILE=FILNAM,access='sequential',form='formatted',
     *     ERR=510,status='old')
c
      IF(filnam.eq.'')then
        inquire(2,name=filnam)
        if(iflag.lt.3)then
          call settextposition(8,15,curpos)
          dummy=settextcolor(12)
          write(*,'(a)')filnam
          dummy=settextcolor(ntextc)
          do 1115 n=len_trim(filnam),1,-1
            if(filnam(n:n).eq.'\')goto 1116
1115      continue
1116      if(n.gt.1)gener=filnam(1:n)
        endif
      endif
      read(2,'(a)',err=2)line
      backspace(2)
C
      if(nlset.lt.1)then
        nlset=1
      else
        NLSET=NLSET+1
      endif
      if(len_trim(filnam).le.30)then
        setnam(nlset)=filnam(1:30)
      else
        nc=len_trim(filnam)
        setnam(nlset)='...'//filnam(nc-26:nc)
      endif
      do 117 n=len_trim(filnam),1,-1
        if(filnam(n:n).eq.'\')goto 118
117   continue
      n=0
118   setnm(nlset)=filnam(n+1:len_trim(filnam))
c
c...parameters for merging with other datasets
c
      IF(NLSET.GT.1.AND.IFLAG.lt.3)THEN
        write(*,'(1x)')
200     WRITE(*,'(1X/
     * ''          Population relative to first set:  '',$)')
        READ(*,'(F20.10)',ERR=200)RELINT
201     WRITE(*,'(1X/
     * ''   Linestyle code (1-10) for this data set:  '',$)')
        READ(*,'(I5)',ERR=201)NLST
        IF(NLST.LT.1.OR.NLST.GT.10)GOTO 201
      ELSE IF(NLSET.GT.1.AND.IFLAG.EQ.3)THEN
        errmes='reading relative intensity RELINT'
        read(4,'(a)',err=500,end=501)line
        backspace(4)
        READ(4,301,err=500,end=501)RELINT
c
        errmes='reading linestyle index NLST'
        read(4,'(a)',err=500,end=501)line
        backspace(4)
        READ(4,300,err=500,end=501)NLST
        IF(NLST.LT.1.OR.NLST.GT.10)NLST=1
      ENDIF
      IF(NLSET.GT.1)THEN
        relati(NLSET)=RELINT
        INFSET(NLSET,2)=NLST
      ELSE
        relati(NLSET)=1.0
        INFSET(NLSET,2)=1
      ENDIF
C
c- - - - - - - - - - - - - - - - - - - -
C   THIS block is repeated until EOF
C
C...read line of data file
5     READ(2,3,ERR=4,END=4)LINE
C
c
c---PICKETT's  .CAT line, with column alignment as below:
c   ,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
c  36796.3472999.9999 -5.7855 3    5.5803  3  410011304 2 1 0 1 . . 1 1 0 0 . .
c   5295.7066   .0020 -9.4551 3     .2300  2      0 314 2 1 2 1     1 1 1 1
c
      if(L(9).eq.'.'.and.L(25).eq.'.')then
        NLINES=NLINES+1
        IF(NLINES.GT.LINMAX)goto 1155
        READ(LINE,1156,ERR=1157)F(NLINES),S(NLINES),ELOW(NLINES)
1156    FORMAT(F13.4,8x,F8.4,2x,F10.4)
c
        S(NLINES)=10.d0**S(NLINES)*RELINT
        IF(LIMIT.EQ.1)THEN
          IF(F(NLINES).GT.FEND.OR.F(NLINES).LT.FSTART.OR.
     *      S(NLINES).LT.SLIMIT)THEN
              NLINES=NLINES-1
              GOTO 5
          ENDIF
        ENDIF
        if(iecho.eq.1)write(5,'(a)')line
c
        call check(line,numbuf)                                         <-----
        read(numbuf,1159,err=1157)
     *     (NQ(NLINES,I),I=1,3),(NQ(NLINES,I),I=7,9),
     *     (NQ(NLINES,I),I=4,6),(NQ(NLINES,I),I=10,12)
1159    format(12i3)
c
        kdelm=nq(nlines,2)-nq(nlines,5)
        kdelp=nq(nlines,3)-nq(nlines,6)
        im=iabs(mod(kdelm,2))
        ip=iabs(mod(kdelp,2))
        dipol(nlines)=' '
        if(im.eq.0.and.ip.eq.1)dipol(nlines)='a'
        if(im.eq.1.and.ip.eq.1)dipol(nlines)='b'
        if(im.eq.1.and.ip.eq.0)dipol(nlines)='c'
c
        M(NLINES)=' '
c
        IF(F(NLINES).LT.FOLD)ISORT=1
        FOLD=F(NLINES)
        IF(S(NLINES).GT.SMAX)SMAX=S(NLINES)
        SET(NLINES)=NLSET
        LST(NLINES)=NLST
        IF(F(NLINES).LT.FMIN)FMIN=F(NLINES)
        IF(F(NLINES).GT.FMAX)FMAX=F(NLINES)
        goto 5
c
1157    nlines=nlines-1
        goto 5
      endif
c
C
C---ASROT type line
c
      IF(L(8).NE.'.')GOTO 5
      NLINES=NLINES+1
1155  IF(NLINES.GT.LINMAX)THEN
        close(2)
        if(iflag.eq.3)close(4)
        if(iecho.eq.1)close(5)
        WRITE(*,41)LINMAX
41      FORMAT(1X/' LINE MAXIMUM OF',I6,', REACHED, no more lines',
     *  ' will be read in'/)
        NLINES=NLINES-1
        INFSET(NLSET,3)=NLINES-NLAST
        GOTO 40
      ENDIF
c
c...read line information assuming it is a single line:
c
c......single PICKETT line (ie six quantum numbers per state), as written
c      by PISORT in pseudo ASROT output:
c   ,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
c  1881.1120    7.78E-07    8,  3,  6    7,  4,  3 b 10, 0, 0-- 9, 0, 0   4.359
c
      READ(LINE,6,ERR=55)F(NLINES),S(NLINES),(NQ(NLINES,I),I=1,6),
     *  DIPOL(NLINES),(nq(nlines,i),i=7,12),ELOW(NLINES)
6     FORMAT(F14.6,1PE10.2,2X,I3,1X,I3,1X,I3,I5,1X,I3,1X,I3,1X,A1,
     *       1x,i2,1x,i2,1x,i2,2x,i2,1x,i2,1x,i2,0PF8.3)
      goto 56
c
c......single genuine ASROT line:
c   ,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
c 25661.627755  1.42E-06   21,  1, 20   20,  1, 19 a.R 0, 1 20.952330     9.275
c 25665.205994  1.49E-07 D 21, 19,      20, 19,    a.R 0, 1  3.809524   266.428
c 25665.205994  1.49E-07 D 21,   , 19   20,   , 19 a.R 0, 1  3.809524   266.428
c
55    READ(LINE,61,ERR=555)F(NLINES),S(NLINES),(NQ(NLINES,I),I=1,6),
     *DIPOL(NLINES),ELOW(NLINES)
61    FORMAT(F14.6,1PE10.2,2X,I3,1X,I3,1X,I3,I5,1X,I3,1X,I3,1X,A1,
     *      17x,0PF10.3)
      do 57 i=7,12
        nq(nlines,i)=0
57    continue
      goto 56
c
555   nlines=nlines-1
      goto 5
c
56    IF(LIMIT.EQ.1)THEN
        IF(F(NLINES).GT.FEND.OR.F(NLINES).LT.FSTART.OR.
     *     S(NLINES)*RELINT.LT.SLIMIT)THEN
          NLINES=NLINES-1
          GOTO 5
        ENDIF
      ENDIF
      if(iecho.eq.1)write(5,'(a)')line
c
C  Column numbers in an ASROT-type file from PISORT:
C
c   ,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
c  1881.1120    7.78E-07    8,  3,  6    7,  4,  3 b 10, 0, 0-- 9, 0, 0   4.359
c
C  Column numbers in an ASROT results file:
C
c   ,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
c 25661.627755  1.42E-06   21,  1, 20   20,  1, 19 a.R 0, 1 20.952330     9.275
c 25665.205994  1.49E-07 D 21, 19,      20, 19,    a.R 0, 1  3.809524   266.428
c 25665.205994  1.49E-07 D 21,   , 19   20,   , 19 a.R 0, 1  3.809524   266.428
C
C...check whether the line is not a doublet and take appropriate action
      IF(L(26).NE.'D')GOTO 31
C
C...implied K+1
      IF(L(37).EQ.' ')THEN
        NQ(NLINES,3)=NQ(NLINES,1)-NQ(NLINES,2)
        NQ(NLINES,6)=NQ(NLINES,4)-NQ(NLINES,5)
      ENDIF
C
C...implied K-1
      IF(L(33).EQ.' ')THEN
        NQ(NLINES,2)=NQ(NLINES,1)-NQ(NLINES,3)
        NQ(NLINES,5)=NQ(NLINES,4)-NQ(NLINES,6)
      ENDIF
C
31    IF(F(NLINES).LT.FOLD)ISORT=1
      FOLD=F(NLINES)
      M(NLINES)=L(26)
      IF(L(26).EQ.'D')S(NLINES)=S(NLINES)*0.5
      S(NLINES)=S(NLINES)*RELINT
      IF(S(NLINES).GT.SMAX)SMAX=S(NLINES)
      SET(NLINES)=NLSET
      LST(NLINES)=NLST
      IF(F(NLINES).LT.FMIN)FMIN=F(NLINES)
      IF(F(NLINES).GT.FMAX)FMAX=F(NLINES)
      GOTO 5
C
c- - - - - - - - - - - - - - - - - - - -
C
4     call clearscreen($gclearscreen)
      WRITE(*,7)NLINES,NLINES-NLAST
7     FORMAT(1X//8x,I7,' lines read altogether'/
     *           8x,I7,' from file:  ',$)
      dummy=settextcolor(12)
      write(*,'(a)')setnam(nlset)
      dummy=settextcolor(ntextc)
      write(*,77)FMIN,FMAX,SMAX
77    format(1x/
     * '         lowest frequency: ',F10.2/
     * '        highest frequency: ',F10.2/
     * '        maximum intensity: ',1PE10.2,' cm-1'/)
      INFSET(NLSET,3)=NLINES-NLAST
      NLAST=NLINES
      close(2)      
      IF(IFLAG.LT.3)THEN
        if(irefr.eq.1)then
          i=0
        else
12        WRITE(*,1)'Any more files (1/0) ?   '
          READ(*,11,ERR=12)I
          IF(I.LT.0.OR.I.GT.1)GOTO 12
11        FORMAT(I5)
        endif
      ELSE
        errmes='reading the ''more data (1), end (0)'' flag'
        read(4,'(a)',err=500,end=501)line
        IF(NLSET.EQ.1.AND.LINE(1:10).EQ.'intensity ')then
          read(4,'(a)',err=500,end=501)line
          read(4,'(a)',err=500,end=501)line
        ENDIF
        backspace(4)
        READ(4,300,err=500,end=501)I
      ENDIF
1     FORMAT(//10X,A\)
      IF(I.EQ.1)GOTO 2
c
c- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
      IF(IFLAG.EQ.3)CLOSE(4)
      if(iecho.eq.1)close(5)
C
C...sort
C
40    if(nlines.le.0)stop
      DO 10 I=1,NLINES
        LNUM(I)=I
10    CONTINUE
      IF(ISORT.EQ.1)THEN
        WRITE(*,20)
20      FORMAT(1X//' **** SORTING lines'/)
        dummy=displaycursor($gcursoroff)
        NSTART=1
        CALL SORTH(NSTART,NLINES)                                       <-----
      ENDIF
C
C...check for LIST file and deal with it if found
C
      nsp=0
      OPEN(5,file=gener(1:len_trim(gener))//'LIST',status='old',err=50)
51    read(5,'(1x,a12,5x,f10.3,4x,f10.3)',err=51,end=50)namspe,fa,fb
      if(fa.le.0.d0.or.fb.le.0.d0)goto 51
      nsp=nsp+1
      fspa(nsp)=fa
      fspb(nsp)=fb
      spenam(nsp)=namspe
      if(nsp.lt.maxspe)then
        goto 51      
      else
        write(*,52)maxspe
52      format(1x//' The current maximum of',I4,
     *  ' measured spectra has been reached'/)
        pause
      endif
50    close(5)
C
C...plot and move about on the stick diagram
C
      CALL COLBEE(1,0,0,0,nhighc,int2(-1))                              <-----
      CALL PLOTS(irefr,iflag)                                           <-----
C
      if(irefr.eq.1)then
        ISORT=0
        FOLD=0.D0
        RELINT=1.0
        NLSET=-1
        NLINES=0
        NLST=1
        SMAX=1.E-12
        FMIN=1.D30
        FMAX=0.D0
        NLAST=0
        limit=0
        if(iflag.eq.3)goto 73  
        if(nlset.eq.-1)goto 76
      endif
      dummy=setexitqq(qwin$exitnopersist)
C
      STOP
c
c...error handling on batch file problems
c
501   iflag=4
500   dummy=settextcolor(15)
      dummy4=setbkcolor(12)
      write(*,504)
504   format(1x//'***** ERROR: problems with control file ')
      dummy=settextcolor(ntextc)
      dummy4=setbkcolor(ntextb)
      if(iflag.ne.4)then
        write(*,502)filcon,errmes,line
      else
        write(*,505)filcon,errmes,line
      endif
502   format(13x,a//
     *       13x,'when ',a//
     *       13x,'encountered line containing:'/
     *  13x,a66//)
505   format(13x,a//
     *       13x,'EOF encountered when ',a//
     *       13x,'last line contained:'/
     *  13x,a66//)
      pause '      Press ENTER to continue'
      CLOSE(4)
      if(iecho.eq.1)close(5)
      if(nlset.ge.1.and.nlines.gt.2)goto 40
      stop
c
c...error handling on missing data file
c
510   dummy=settextcolor(15)
      dummy4=setbkcolor(12)
      write(*,511)
511   format(1x//'***** ERROR: cannot read or missing data file:')
      dummy=settextcolor(ntextc)
      dummy4=setbkcolor(ntextb)
      write(*,512)filnam
512   format(13x,a//)
      pause '      Press ENTER to continue'
c
      if(iflag.eq.3)then
        errmes='skipping to the next filename'
        read(4,'(a)',err=500,end=501)line
        if(line(1:10).eq.'intensity ')then
          read(4,'(a)',err=500,end=501)line
          read(4,'(a)',err=500,end=501)line
        endif
      endif
c
      goto 2
c
      STOP
      END
C
C_____________________________________________________________________________
C
      subroutine check(linein,line)
c
c...routine to decode quantum numbers:
c     --  two digit negative coded  a1 for -11, b1 for -21 etc., up to i1
c         for -91
c     --  three digit positive coded A0 for 100, B0 for 110 etc., up to N0
c         for 240
c   into standard I3 notation
c
      character linein*80,line*40,cdig
c
c...transfer two digit quantum numbers from columns 56:79 of LINEIN
c   to three digit fields in columns 1:36 of LINE
c
      nnn=56
      do 1158 n=1,12
        nn=(n-1)*3+1
        line(nn:nn)=' '
        line(nn+1:nn+2)=linein(nnn:nnn+1)
        nnn=nnn+2
1158  continue
c
c...Go through each of the twelve quantum numbers in turn, check, and if
c   necessary convert
c
      do 1159 n=1,12
        i=(n-1)*3+1
        j=i+2
        read(line(i:j),'(i3)',err=1)k
        goto 1159
1       read(line(i+1:i+1),'(a)')cdig
c
        if( .not.(cdig.ge.'a'.and.cdig.le.'i') .and.
     *      .not.(cdig.ge.'A'.and.cdig.le.'N') )then
          write(*,111)'Quantum number checks failed on:',
     *    i,j,line(i:j),line,linein(1:60),linein(61:79)
111     format(1x//' **** ERROR: ',a//
     *      ' Columns ',I2,':',I3,'-->',a//
     *      ' in buffer line-->',a//
     *      18x,6(10H....,....I)//
     *    ' original .CAT line:'//
     *      ' Columns  1: 60-->',a/
     *      ' Columns 61: 79-->',a//
     *      18x,6(10H....,....I)//)
          stop
        endif
c
        read(line(j:j),'(i1)')k
        if(cdig.ge.'a'.and.cdig.le.'i')then
          ntens=ichar(cdig)-ichar('a')+1
          k=-(k+10*ntens)
        endif
        if(cdig.ge.'A'.and.cdig.le.'N')then
          ntens=ichar(cdig)-ichar('A')+1
          k=(k+(9+ntens)*10)
        endif
        write(line(i:j),'(i3)')k
c
1159  continue
c
      return
      end
C_____________________________________________________________________________
c
      SUBROUTINE COLBEE(DUM1,DUM2,DDET,JJ,nhighc,LCSCHE)
C
C...This routine is first executed immediately prior to plotting and assigns
C   colour values to each line (stored in NCOLOR and LCOLOR)
C   Further calls are then used to introduce highligting (colours only
c   changed in NCOLOR) or to reset colour schemes
C
C    DUM1 = data set number from which lines are to be highlighted
C           (highlight transitions from all sets if negative)
C    DUM2 = transition type index for type of transition to be highlighted
C    DDET = type of quantum number to be highlighted (1 to 6 select the six
C           lower state quantum numbers)
C           if set to 0 then colours are reset
C           if set to -1 then all lines of a given set are highlighted
C           if set to -2 then all lines of a given transition with type are
C              highlighted
C      JJ = value of quantum number to be highlighted
C  nhighc = the current highlighting colour
C  LCSCHE = the colour scheme to be used (-1 colour assigned according
C           to transition type, +1 colour according to line code identifier
C           for the data set (of importance only if DDET=0)
C
C
      PARAMETER (MAXLIN=100000,maxfil=20)
      PARAMETER (ntextc=0, ntextb=7)
c
      CHARACTER DIPOL(MAXLIN),M(MAXLIN),setnam(maxfil)*30,
     * setnm(maxfil)*20,gener*50
      INTEGER*1 SET(MAXLIN),LST(MAXLIN),DUM1
      REAL*4 S(MAXLIN),SMAX,ELOW(maxlin)
      REAL*8 F(MAXLIN),FMIN,FMAX
      INTEGER*4 LNUM(MAXLIN),I,J,INFSET(maxfil,3)
      INTEGER*2 JJ,DDET,dddet,DUM2,NQ(MAXLIN,12),LCSCHE
      INTEGER*1 NCOLOR(MAXLIN),lcolor(maxlin)
      COMMON /FRBLK/F/SBLK/FMIN,FMAX,ELOW,S,SMAX,NLINES
      COMMON /ORIGLN/SET,LST,NLSET,NCOLOR,LCOLOR
      COMMON /LNUMS/LNUM/DOUBL/M
      COMMON /QNUMS/NQ
      COMMON /DIP/DIPOL
      COMMON /SETINF/INFSET,SETNAM,SETNM,gener
C
C...H i g h l i g h t   s e l e c t e d   l i n e s
C
      IF(DDET.EQ.0) GOTO 20
C
c...highlight according to value of transition type index equal to DUM2
c
      IF(DDET.EQ.-2)THEN
        DO 22 I=1,NLINES
          J=LNUM(I)
          IF(SET(J).eq.DUM1.or.DUM1.lt.0)then
            JD=(NQ(J,1)-NQ(J,4))*100+(NQ(J,2)-NQ(J,5))*10
     *        +(NQ(J,3)-NQ(J,6))
            IF(JD.eq.DUM2)NCOLOR(J)=nhighc
          endif
22      CONTINUE
      ENDIF
C
C...highlight all lines from data set defined by DUM1 or all lines in all
C   datasets if DUM1 is -ve
C
      IF(DDET.EQ.-1)THEN
        DO 100 I=1,NLINES
          J=LNUM(I)
          IF(SET(J).EQ.DUM1.OR.DUM1.LT.0)NCOLOR(J)=nhighc
100     CONTINUE
      ENDIF
C
C...highlight according to value JJ of the quantum number defined by DDET
C
      IF(DDET.GT.0)THEN
        DO 10 I=1,NLINES
          J=LNUM(I)
          IF(SET(J).eq.DUM1.or.DUM1.lt.0)then
            dddet=(ddet/4+1)*3+ddet
            IF( JJ.EQ.NQ(J,ddDET) )NCOLOR(J)=nhighc
          endif
10      CONTINUE
      ENDIF
C
      RETURN
C
C
C...R e s e t   c o l o u r s  to transition-type colours
C
20    if(lcsche.eq.1)goto 21
c
      DO 12 I=1,NLINES
        J=LNUM(I)
c
c...JD=1,2,3 for P,Q,R
c
        JD=NQ(J,1)-NQ(J,4)+2
C
C...assign default colour for transition with unknown selection rules,
c   defined by 1/ DeltaJ not -1,0,1
c              2/ Sum of K+1 and K-1 not J or J+1
c              3/ deltaK-1 and deltaK+1 both not zero
c
        if(JD.lt.1.or.JD.gt.3.or.NQ(j,2).lt.0.or.NQ(j,5).lt.0)then
          NCOLOR(J)=30
          goto 11
        endif
        JKM=NQ(J,1)+1-NQ(J,2)-NQ(J,3)
        JKP=NQ(J,4)+1-NQ(J,5)-NQ(J,6)
        if(jkm.lt.0.or.jkm.gt.1.or.jkp.lt.0.or.jkp.gt.1)then
          NCOLOR(J)=30
          goto 11
        endif
        JKM=NQ(J,2)-NQ(J,5)
        JKP=NQ(J,3)-NQ(J,6)
        if(jkm.eq.0.and.jkp.eq.0)then
          NCOLOR(J)=30
          goto 11
        endif
        if((jkm/2)*2.eq.jkm.and.(jkp/2)*2.eq.jkp)then
          NCOLOR(J)=30
          goto 11
        endif
C
C...a-type transitions (reds - pallette colours 31,32,33)
C
        IF(DIPOL(J) .EQ.'a' )then
          NCOLOR(J)=30+JD
          GOTO 11
        ENDIF
C
C...b-type transitions (greens - pallette colours 34,35,36)
C
        IF(DIPOL(J) .EQ.'b' )THEN
          NCOLOR(J)=33+JD
          GOTO 11
        ENDIF
C
C...c-type transitions (blues - pallette colours 37,38,39)
C
        IF(DIPOL(J) .EQ.'c' ) THEN
          NCOLOR(J)=36+JD
          goto 11
        ENDIF
11      lcolor(j)=ncolor(j)
12    CONTINUE
      RETURN
C
C
C...R e s e t   c o l o u r s  to data set colours, with colour determined by
C                              the line code identifier in the input
C
21    DO 30 I=1,NLINES
        J=LNUM(I)
        IK=set(J)
        ncolor(j)=40+infset(ik,2)
        lcolor(j)=ncolor(j)
30    CONTINUE
C
C
      RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE PLOTS(irefr,iflag)
C
C   This routine handles all the operations while in graphics mode,
C   details of screen refresh are handled by routine STICKS
C
C   IREFR is set to 1 on output if data is to be refreshed, and is to be 
C         found set to 1 on input if refresh has just taken place,
C         otherwise IREFR=0 on input and exit 
C   IFLAG = 1,2,3 defines the type of input that is being used
C
      USE DFLIB
C
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
C
      LOGICAL*2 true
      PARAMETER (MAXLIN=100000,maxspe=500,TRUE=.TRUE.,maxfil=20)
      PARAMETER (ntextc=0, ntextb=7)
c
      REAL*4 S(MAXLIN),SMAX,ELOW(maxlin)
      REAL*8 F(MAXLIN),FMIN,FMAX,F1,F2,FMARK,FSTEP,FSHIFT,FL,FH,
     * FF1,FF2,htmax,hwhh,sshift,fspa(maxspe),fspb(maxspe),dopspl
      INTEGER*1 SET(MAXLIN),LST(MAXLIN),DUMSET
      REAL*8 RMTOP,RSMALL,RLARGE,YSTEP,FCDET,RM
      INTEGER*4 LNUM(MAXLIN),INFSET(maxfil,3),ifmark,i,ifl,ifh,N,
     * L,JDET,JJ,IST,IFIN,NLINES
      INTEGER*2 IK,inkey,j,JCDET,NQ(MAXLIN,12)
      INTEGER*2 INTADD,LINDET,NLDET,DUMmy2,DDET,dddet,JD,LSTYLS,LCSCHE
      CHARACTER KK,DIPOL(MAXLIN),M(MAXLIN),TYPETR(4),spenam(maxspe)*12,
     * OUTSTR*21,DTOP*3
      CHARACTER SETNAM(maxfil)*30,setnm(maxfil)*20,gener*50
      INTEGER*2 maxx,maxy,mymode,myrows,mycols,linofs
      CHARACTER*79 toplin,botlin,emplin,inf,seclin
      INTEGER*4 DUMmy4,BKC,CDDET,bkcol
      INTEGER*1 NCOLOR(MAXLIN),LCOLOR(MAXLIN)
c
      COMMON /limits/wxy,maxx,maxy,LINOFS,curpos,ixy,
     *               mymode,myrows,mycols
      COMMON /ORIGLN/SET,LST,NLSET,NCOLOR,LCOLOR
      COMMON  /FRBLK/F
     *         /SBLK/FMIN,FMAX,ELOW,S,SMAX,NLINES
      COMMON  /QNUMS/NQ
      COMMON  /LNUMS/LNUM/DOUBL/M
      COMMON    /DIP/DIPOL
      COMMON  /LINES/toplin,botlin,emplin,seclin
      COMMON /SETINF/INFSET,SETNAM,setnm,gener
      COMMON  /SPECS/fspa,fspb,spenam,nsp
      real*4 relati(maxfil)
      equivalence (relati(1),infset(1,1))
c
c-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
c
c     COLOURS: standard pallette colours are:
c
c     0 - black         4 - dark red        8 - dark grey    12 - red
c     1 - dark blue     5 - dark purple     9 - blue         13 - purple
c     2 - dirty green   6 - dirty yellow   10 - green        14 - yellow
c     3 - blue/green    7 - grey           11 - light blue   15 - white
c
c...colours for the eight colour schemes
c
      INTEGER*4 bkcolor(8) / 21, 22, 23, 24, 25, 26, 27, 28/
      INTEGER*4 cursco(8)  / 14,  2,  7, 14, 14,  2, 15, 14/
      INTEGER*4 bordco(8)  / 15, 15, 15,  0, 15,  1,  1,  5/
      INTEGER*4 highco(8)  / 15, 15, 15,  0, 15,  1,  0,  5/
      DATA TYPETR/'P','Q','R',' '/
c
      if(irefr.eq.0)then
        nswtch=0
        istico=0
        hwhh=1.D0
        dopspl=0.d0
        ictyp=1
        icder=2
        sshift=0.0d0
        ncursp=1
      endif
c
c...Custom pallette colours (they have to be defined each time the configuration
c   of the graphics window is changed - i.e. also after calling NARGR) 
C
c...colours for use as backgrounds, pallette colours 21-28
c
777   dummy4=remappalettergb(21, #006E0000)
      dummy4=remappalettergb(22, #008C7800)
      dummy4=remappalettergb(23, #00B4B4B4)
      dummy4=remappalettergb(24, #00C5C5C5)
      dummy4=remappalettergb(25, #00141414)
      dummy4=remappalettergb(26, #00CC9933)
      dummy4=remappalettergb(27, #00A8A800)
      dummy4=remappalettergb(28, #0072BCDE)
c
c...colours for transition types, pallette colours 30-39
c
c...unidentified
c     dummy4=remappalettergb(30, #00FF00FF)
      dummy4=remappalettergb(30, #0000FFFF)
c...aP,aQ,aR,
      dummy4=remappalettergb(31, #000064C8)
      dummy4=remappalettergb(32, #008787FF)
      dummy4=remappalettergb(33, #000000FF)
c...bP,bQ,bR,
      dummy4=remappalettergb(34, #00A7DFA7)
      dummy4=remappalettergb(35, #00BAE967)
      dummy4=remappalettergb(36, #0000FF00)
c...cP,cQ,cR,
      dummy4=remappalettergb(37, #00C2B786)
c     dummy4=remappalettergb(38, #00FF0E65)
      dummy4=remappalettergb(38, #00FF009C)
      dummy4=remappalettergb(39, #00FF6A66)
c
c...dataset colours mapped from linestyle number: pallette colours 41-50
c
      dummy4=remappalettergb(41, #0000FFFF)
      dummy4=remappalettergb(42, #00FFC0C0)
      dummy4=remappalettergb(43, #00C0C000)
      dummy4=remappalettergb(44, #00BAE967)
      dummy4=remappalettergb(45, #00FF80FF)
      dummy4=remappalettergb(46, #00A7DFA7)
      dummy4=remappalettergb(47, #0000FF00)
      dummy4=remappalettergb(48, #000000FF)
      dummy4=remappalettergb(49, #00FF00FF)
      dummy4=remappalettergb(50, #00FF6A66)
c
c-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
C
      if(nswtch.eq.0.and.irefr.eq.0)then
        INTADD=-1
        LSTYLS=-1
        LCSCHE=-1
        lindet=+1
        IFMARK=1
        L=1
        JDET=1
        BKC=1
        ncursc=cursco(bkc)
        nbordc=bordco(bkc)
        nhighc=highco(bkc)
      endif
c
      if(irefr.eq.1)then
        if(ddet.ne.0)then
          CALL COLBEE(DUMSET,0,   0,    0,nhighc,LCSCHE)                <-----
          CALL COLBEE(DUMSET,0,DDET,JCDET,nhighc,LCSCHE)                <-----
        else
          CALL COLBEE(1,0,0,0,nhighc,LCSCHE)                            <-----
        endif      
      endif
C
C...Initialize graphics
C
      if(nswtch.eq.0.and.irefr.eq.0)then
        F1=FMIN
        F2=FMAX
        FMARK=0.5D0*(F1+F2)
        RLARGE=SMAX
      endif
      dummy=displaycursor($gcursoroff)
C
c...various patches to account for differences in FORTRANs and resolutions
c
      if(mycols.eq.80)then
        itxt=0
      else
        itxt=(mycols-80)/2
      endif
c
      if(((maxy+1)/myrows)*myrows.eq.maxy+1)then
        incr=0
      else
        incr=maxy-(maxy/myrows)*myrows
      endif
c
      NHORPT=maxx+1
      dummy4 = setbkcolor( bkcolor(BKC) )
      DUMmy2=settextcolor(ntextc)
      DDET=0
      JCDET=0
C
C...definition of pixel limits for the graphics viewport to allow erasure
C   of graphics leaving the top and bottom text lines
C   (note that pixel origin is now moved to the corner of the viewport)
c
C   Y-axis of spectrum spans 500 YSTEP units when myrows=30 or 
C                            250 YSTEP units when myrows=17
c   baseline is at -YSTEP to point out the very small lines
c   marker horizontal line is at -5*YSTEP
c   markers are 5 and 13 YSTEP units long
c
      dummy4=setbkcolor(ntextb)
      call setviewport(2,2*LINOFS-2,maxx-2,maxy-2*LINOFS+2)
      call clearscreen($GCLEARSCREEN)
C
      YSTEP=1.d0/500.d0*RLARGE
      if(myrows.eq.17)ystep=ystep*2.d0
      RSMALL=-18.d0*YSTEP
      DUMmy2=setwindow(true,F1,RSMALL,F2,RLARGE)
C
C   Beginning of main display loop which is executed each time a change in
C   the display is performed
C
C...Graphics bounds and bordering horizontal lines
C
7     DUMMY2=SETCOLOR( nbordc )
      bkcol=bkcolor(bkc)
      dummy4 = setbkcolor( bkcol )
      dummy2=setwindow(true,F1,RSMALL,F2,RLARGE)
      CALL clearscreen($GVIEWPORT)
      CALL  moveto_w(F1,-YSTEP,wxy)
      dummy=lineto_w(F2,-YSTEP)
      dummy=lineto_w(F2,RLARGE)
      dummy=lineto_w(F1,RLARGE)
      dummy=lineto_w(F1,-YSTEP)
      DUMMY2=SETCOLOR( ntextb )
      CALL  moveto_w(F1,-2.d0*YSTEP,wxy)
      dummy=lineto_w(F2,-2.d0*YSTEP)
      CALL  moveto_w(F1,-3.d0*YSTEP,wxy)
      dummy=lineto_w(F2,-3.d0*YSTEP)
      CALL  moveto_w(F1,-4.d0*YSTEP,wxy)
      dummy=lineto_w(F2,-4.d0*YSTEP)
      DUMMY2=SETCOLOR( nbordc )
C
C...PLOT - redefine floating-point window, clear and plot
C
      htmax=rlarge-ystep
      CALL STICKS(F1,F2,FSTEP,RM,htmax,YSTEP,INTADD,LSTYLS,LCSCHE,      <-----
     *  itxt,bkcol,nbordc,istico)
      if(istico.ne.0)
     *  CALL PLOSPE(F1,F2,HTmax,YSTEP,sshift,hwhh,dopspl,ictyp,icder)   <-----
c
c...cursor and heading (if transition information is wanted on the header
c   then a jump to transition inspection code at label 230 is made - return
c   is to label 1 via code at label 722)
C
      RMTOP=RLARGE/3.d0
      dummy=setwritemode($GXOR)
      DUMMY2=SETCOLOR( ncursc )
      CALL setlinestyle(#3333)
      CALL moveto_w(FMARK,RMTOP,wxy)
      dummy2=lineto_w(FMARK,RSMALL)
      dummy=setwritemode($GPSET)
      CALL setlinestyle(#FFFF)
c
      if(lindet.gt.0)goto 230
      WRITE(toplin,120)FMARK
120   FORMAT(' CURSOR:',2x,F15.4)
      dummy4 = setbkcolor( ntextb )
      dummy2=settextcolor( ntextc )
      seclin=emplin
      CALL settextposition(1,int2(itxt+1),curpos)
      CALL outtext(toplin//' ')
      CALL settextposition(2,int2(itxt+1),curpos)
      write(seclin(1:5),'(i5)')ncursc
      CALL outtext(seclin//' ')
      CALL settextposition(myrows,int2(itxt+2),curpos)
      CALL outtext('                    ')
c
C...option selection:
C
1     IK=INKEY(j)
      KK=CHAR(IK)
C
C             A,S - shift screen window over the spectrum
C             Q,E - X-axis zoom
C             W,Z - Y-axis zoom
C             K,L - cursor right/left/quarter
C             ,   - center/quarter cursor
C             2,3 - vertical shift of sticks/contours
C
      IF(KK.EQ.'A'.OR.KK.EQ.'a')GOTO 14
      IF(KK.EQ.'S'.OR.KK.EQ.'s')GOTO 15
      IF(KK.EQ.'Q'.OR.KK.EQ.'q')GOTO 11
      IF(KK.EQ.'E'.OR.KK.EQ.'e')GOTO 10
      IF(KK.EQ.'W'.OR.KK.EQ.'w')GOTO 17
      IF(KK.EQ.'Z'.OR.KK.EQ.'z')GOTO 16
      IF(KK.EQ.'K'.OR.KK.EQ.'k')GOTO 19
      IF(KK.EQ.'L'.OR.KK.EQ.'l')GOTO 18
      IF(KK.EQ.',')GOTO 1018
      IF(KK.EQ.'3'.OR.KK.EQ.'#')GOTO 60
      IF(KK.EQ.'2'.OR.KK.EQ.'@')GOTO 61
C
C         D/R/T - highlight lines according to qn's/data set/transition type
C             F - frequency limits for display
C  <home>/<end> - go to beginning/end of data
C           O/I - information on displayed lines/data sets
C             G - gle output
C             M - type of display - stick/contour/stick+contour
C
      IF(KK.EQ.'D'.OR.KK.EQ.'d')GOTO 26
      IF(KK.EQ.'R'.OR.KK.EQ.'r')GOTO 27
      IF(IK.EQ.-71)goto 600
      IF(IK.EQ.-79)goto 601
      IF(KK.EQ.'T'.OR.KK.EQ.'t')GOTO 29
      IF(KK.EQ.'F'.OR.KK.EQ.'f')GOTO 22
      IF(KK.EQ.'O'.OR.KK.EQ.'o')GOTO 20
      IF(KK.EQ.'I'.OR.KK.EQ.'i')GOTO 28
      IF(KK.EQ.'G'.or.KK.EQ.'g')GOTO 30
      IF(KK.EQ.'M'.or.KK.EQ.'m')GOTO 31
C
C             Y - toggles addition of intensities
C             U - toggle use of different linestyles
C             P - toggle colouring by transitions type/data set
C             C - toggle overall colouring scheme
C             H - display HELP screen
C         <ESC> - refresh input
C
      IF(KK.EQ.'Y'.OR.KK.EQ.'y')GOTO 21
      IF(KK.eq.'U'.or.KK.eq.'u')then
        LSTYLS=-LSTYLS
        GOTO 7
      ENDIF
      IF(KK.EQ.'P'.OR.KK.EQ.'p')GOTO 224
      IF(KK.EQ.'C'.OR.KK.EQ.'c')GOTO 25
      IF(KK.EQ.'H'.OR.KK.EQ.'h')GOTO 23
      IF(IK.EQ.27)then                                                  ESC
        if(iflag.eq.3.or.nlset.eq.1)then
          irefr=1
          return
        endif
      ENDIF
C
C up/down arrow - toggle through overlapped lines
C
      IF(iK.EQ.-72.AND.TOPLIN(21:21).EQ.'.')GOTO 2400
      IF(iK.EQ.-80.AND.TOPLIN(21:21).EQ.'.')GOTO 2401
C
      IF(IK.EQ.-67)GOTO 24
C
C             ^ - toggle window height between 30 and 17 rows
c
      if(KK.eq.'^')then
        call nargr                                                      <-----
        nswtch=1
        goto 777
      endif         
c
c unpublished test option
c
      IF(KK.eq.'v'.and.LINDET.lt.0)then
        ncursc=ncursc+1
        if(ncursc.gt.15)ncursc=0
        goto 7
      ENDIF
      IF(KK.eq.'V'.and.LINDET.lt.0)then
        ncursc=ncursc-1
        if(ncursc.lt.0)ncursc=15
        goto 7
      ENDIF
C
      IF(IK.NE.13)GOTO 1
C
C...exit control
C
      DUMMY= SETTEXTCOLOR(ntextc)
      dummy4 = setbkcolor(ntextb)
      CALL settextposition(2,int2(itxt+1),curpos)
      CALL outtext(emplin//' ')
      CALL settextposition(1,int2(itxt+1),curpos)
      CALL outtext(emplin//' ')
      DUMMY=SETTEXTCOLOR(15)
      dummy4=setbkcolor (12)
      WRITE(outstr,'(A)')' ARE YOU SURE (Y/N) ?'
      CALL settextposition(1,int2(itxt+1),curpos)
      CALL outtext(outstr(1:21))
916   IK=INKEY(j)
      KK=CHAR(IK)
      IF(KK.EQ.'Y'.OR.KK.EQ.'y')GOTO 915
      IF(KK.NE.'N'.AND.KK.NE.'n')THEN
        GOTO 916
      ENDIF
      dummy4 = setbkcolor( ntextb )
      dummy2=settextcolor( ntextc )
      CALL settextposition(1,int2(itxt+1),curpos)
      CALL outtext(toplin//' ')
      CALL settextposition(2,int2(itxt+1),curpos)
      CALL outtext(seclin//' ')
      GOTO 1

915   dummy2=setvideomode($DEFAULTMODE)
      irefr=0
      GOTO 100
C
C...zoom-in in frequency (with E)
C
10    FR=F2-F1
      FINCR=0.25D0*FR
      IF(KK.EQ.'e')FINCR=0.45D0*FR
      F1=FMARK-FINCR
      if(f1.lt.0.d0)f1=0.d0
      F2=FMARK+FINCR
      if(f1.lt.0.d0)then
        f1=0.d0
        f2=2.d0*fmark
      endif
      GOTO 7
C
C...zoom-out in frequency (with Q)
C
11    FR=F2-F1
      FINCR=0.5D0*FR
      IF(KK.EQ.'q')FINCR=0.1D0*FR
      F1=F1-FINCR
      IF(F1.LT.0.D0)F1=0.D0
      F2=F2+FINCR
      GOTO 7
C
C...Y-axis shift upwards (with 3)
C
60    range=htmax
      if(kk.eq.'3')then
        range=-0.02*range
      else
        range=-0.10*range
      endif
63    sshift=sshift+range
      goto 7
C
C...Y-axis shift downwards (with 2)
C
61    range=htmax
      if(kk.eq.'2')then
        range= 0.02*range
      else
        range= 0.10*range
      endif
      goto 63
C
c...go to beginning of data (with <HOME>)
c
600   IF(IK.EQ.-71)THEN
        fmark=F2-F1
        F1=FMIN
        F2=f1+fmark
        fmark=0.5D0*(F1+F2)
        GOTO 161
      ENDIF
C
c...go to end of data (with <END>)
c
601   IF(IK.EQ.-79)THEN
        fmark=F2-F1
        f2=FMAX
        f1=F2-FMARK
        fmark=0.5D0*(F1+F2)
        GOTO 161
      ENDIF     
C
C...shift viewing window to the left (with A)
C
14    FR=F2-F1
      FSHIFT=FR*0.5D0
      IF(KK.EQ.'a')FSHIFT=FR*0.1D0
      F1=F1-FSHIFT
      IF(F1.LT.0.D0)THEN
        F1=0.D0
        FSHIFT=F2-(F1+FR)
      ENDIF
      F2=F2-FSHIFT
      FMARK=FMARK-FSHIFT
      GOTO 7
C
C...shift viewing window to the right (with S)
C
15    FR=F2-F1
      FSHIFT=FR*0.5D0
      IF(KK.EQ.'s')FSHIFT=FR*0.1D0
      F1=F1+FSHIFT
      F2=F2+FSHIFT
      FMARK=FMARK+FSHIFT
      GOTO 7
C
C...zoom-out in height (with Z)
C
16    HMULT=2.D0
      IF(KK.EQ.'z')HMULT=1.1D0
      RLARGE=HMULT*RLARGE
161   YSTEP=1.d0/500.d0*RLARGE
      if(myrows.eq.17)ystep=ystep*2.d0
      RSMALL=-18.d0*YSTEP
      GOTO 7
C
C...zoom-in in height (with W)
C
17    HMULT=0.5D0
      IF(KK.EQ.'w')HMULT=0.95D0
      RLARGE=HMULT*RLARGE
      GOTO 161
C
C...Shift of cursor to the left (with K)
C
19    dummy=setwritemode($GXOR)
      DUMMY2=SETCOLOR( ncursc )
      CALL setlinestyle(#3333)
      CALL moveto_w(FMARK,RMTOP,wxy)
      dummy2=lineto_w(FMARK,RSMALL)
      FMARK=FMARK-8.D0*FSTEP
      IF(KK.EQ.'k')FMARK=FMARK+7.D0*FSTEP
      IF(FMARK.LT.F1)FMARK=F1
C
719   CALL moveto_w(FMARK,RMTOP,wxy)
      dummy2=lineto_w(FMARK,RSMALL)
      CALL setlinestyle(#FFFF)
      dummy=setwritemode($GPSET)
      if(lindet.gt.0)goto 230

720   WRITE(toplin,120)FMARK
      seclin=emplin
722   DUMMY2=SETTEXTCOLOR( ntextc )
      dummy4 = setbkcolor( ntextb )
      CALL settextposition(1,int2(itxt+1),curpos)
      CALL outtext(toplin//' ')
      CALL settextposition(2,int2(itxt+1),curpos)
      CALL outtext(seclin//' ')
c
      CALL settextposition(myrows,int2(itxt+2),curpos)
      if(toplin(2:2).eq.'C')then
        CALL outtext('                    ')
      else
        DUMMY2=SETTEXTCOLOR( 12 )
        ik=set(l)
        call outtext(setnm(ik))
        DUMMY2=SETTEXTCOLOR( ntextc )
      endif
c
c...place a rectangle (a space) in the line colour
      if(nldet.ne.0)then
        if(lincol.eq.nhighc)then
          dummy4 = setbkcolor( lcolor(L) )
          CALL settextposition(1,itxt+69,curpos)
          call outtext(' ')
          dummy4 = setbkcolor( lincol )
          CALL settextposition(2,itxt+69,curpos)
          call outtext(' ')
        else
          dummy4 = setbkcolor( lincol )
          CALL settextposition(1,itxt+69,curpos)
          call outtext(' ')
        endif
        dummy4 = setbkcolor( ntextb )
      endif
c
c...if cursor is within frequency range of a recorded spectrum write its name
c   on the second line
      if(nsp.gt.0)then
        ifabs=nint(dsign(1.d0,fmark-fspa(ncursp)))+
     *        nint(dsign(1.d0,fmark-fspb(ncursp)))
        ifab=ifabs
        if(ifab.eq. 2)i= 1
        if(ifab.eq.-2)i=-1
C
2100    if(iabs(ifab).le.1)goto 2101
        if(i.eq.-1.and.ifab.eq.2)goto 2103
        if(i.eq.1.and.ifab.eq.-2)goto 2103
c       if(ifab*ifabs.lt.0)goto 2102
c
2103      ncursp=ncursp+I
          if(ncursp.gt.nsp)then
            ncursp=nsp
            goto 2102
          endif
          if(ncursp.eq.0)then
            ncursp=1
            goto 2102
          endif

        ifab =nint(dsign(1.d0,fmark-fspa(ncursp)))+
     *        nint(dsign(1.d0,fmark-fspb(ncursp)))
        goto 2100
c
2101    CALL settextposition(2,itxt+2,curpos)
        DUMMY2=SETTEXTCOLOR(  9 )
        call outtext(spenam(ncursp))
c
2102    continue
      endif
c
      IF(DDET.LE.0 .OR. NLDET.EQ.0) GOTO 1
C
C...change colour of selected quantum number when highlighting lines
      dddet=(ddet/4+1)*3+ddet
      IF ( JCDET.EQ.NQ(L,DDdET)) THEN
        WRITE(dtop,'(I3)')NQ(L,DdDET)
        DUMMY2=SETTEXTCOLOR( 12 )
        dddet=ddet-(ddet/4)*3
        CALL settextposition(int2(ddet/4+1),
     *        int2(itxt+53+dddet*4),curpos)
        CALL outtext(dtop)
      ENDIF
c      
      GOTO 1
C
C...Shift of cursor to the right (with L)
C
18    dummy=setwritemode($GXOR)
      DUMMY2=SETCOLOR( ncursc )
      CALL setlinestyle(#3333)
      CALL moveto_w(FMARK,RMTOP,wxy)
      dummy2=lineto_w(FMARK,RSMALL)
      FMARK=FMARK+8.D0*FSTEP
      IF(KK.EQ.'l')FMARK=FMARK-7.D0*FSTEP
      IF(FMARK.GT.F2)FMARK=F2
      GOTO 719
C
C...Centre cursor on the screen (with ,)
C
1018  dummy=setwritemode($GXOR)
      DUMMY2=SETCOLOR( ncursc )
      CALL setlinestyle(#3333)
      CALL moveto_w(FMARK,RMTOP,wxy)
      dummy2=lineto_w(FMARK,RSMALL)
      I=1+NINT( 4.D0*(FMARK-F1)/(F2-F1) )
      IF(I.GE.4)I=1
      FMARK=F1+0.25D0*REAL(I)*(F2-F1)
      GOTO 719
C
C...Write information on lines centred on the cursor (with O)
C
20    CALL HUNTF(NLINES,FMARK,IFMARK)                                   <-----
      increm=myrows-4
      I=IFMARK
      IF(I.EQ.0)I=1
      IF(I.EQ.NLINES)I=NLINES-1
      IF(DABS(F(I+1)-FMARK).LT.DABS(F(I)-FMARK))I=I+1
      IST=I-increm/2
      IF(IST.LT.1)IST=1
      IFIN=IST+increm-1
      IF(IFIN.GT.NLINES)then
        IFIN=NLINES
        ist=ifin-increm+1
        if(ist.lt.1)ist=1
      endif
c
      DUMMY2=SETTEXTCOLOR( ntextc )
      dummy4 = setbkcolor( ntextb )
111   CALL clearscreen($GCLEARSCREEN)
      write(*,114)
114   format('Set    Frequency  Abs.coef.      U P P E R',
     * '              L O W E R         E.low'/)
      DO 103 JJ=IST,IFIN
        L=LNUM(JJ)
        IK=SET(L)
        IF(IK.LT.10)KK=CHAR(48+IK)
        IF(IK.GT.9)KK=CHAR(55+IK)
        DUMMY4=setbkcolor( lcolor(L) )
        write(*,'('' '',$)')
        DUMMY4=setbkcolor( ntextb )
c
        if(ncolor(l).eq.nhighc)then
          dummy4 = setbkcolor(15)
          write(*,'(a1,'':'',$)')KK
          dummy4 = setbkcolor( ntextb )
        else
          write(*,'(a1,'':'',$)')KK
        endif
c
        IF(JJ.EQ.I)dummy4 = setbkcolor(15)
        WRITE(*,1104)F(JJ),S(L),(NQ(L,II),II=1,3),
     *    (NQ(L,II),II=7,9),(NQ(L,II),II=4,6),(NQ(L,II),II=10,12),
     *    elow(L)
        IF(JJ.EQ.I)dummy4 = setbkcolor( ntextb )
103   CONTINUE
1104  FORMAT(F13.4,1PE10.2,
     *    I5,2I3,i4,2i3,' <-', I4,2I3,i4,2I3 ,0PF9.3 )
c
231   DUMmy2=settextcolor(ntextc)
      WRITE(inf,106)
106   FORMAT(' Use <PgUp> <PgDown> keys to scroll',10X,
     *  'ENTER returns to the stick display')
      CALL settextposition(myrows,int2(itxt+1),curpos)
      CALL outtext(inf)
c
107   IK=INKEY(J)
      IF(IK.EQ.0)GOTO 107
      IF(IK.EQ.13)THEN
        dummy4=setbkcolor(ntextb)
        CALL clearscreen($GCLEARSCREEN)
        GOTO 7
      ENDIF
      kk=char(ik)
      IF(iK.EQ.-81)THEN
        IST=IST+increm
        IFIN=IFIN+increm
        IF(IFIN.GT.NLINES)THEN
          IST=NLINES-increm+1
          IFIN=NLINES
        ENDIF
        GOTO 111
      ENDIF
      IF(iK.EQ.-73)THEN
        IST=IST-increm
        IFIN=IFIN-increm
        IF(IST.LT.1)THEN
          IST=1
          IFIN=increm
        ENDIF
        GOTO 111
      ENDIF
      GOTO 107
C
C...Write the help text (with H)
C
23    dummy4=setbkcolor(ntextb)
      DUMmy2=settextcolor(ntextc)
      CALL clearscreen($GCLEARSCREEN)
      WRITE(*,232)
232   FORMAT(1x/'_____SUMMARY OF COMMANDS ACTIVE IN GRAPHICS MODE',
     * 32(1H_)//
     * '   W/Z, Q/E  - up/down keys for vertical, horizontal scaling'/
     * '   A/S, 2/3  - shift display left/right and spectrum up/down'/
     * '      K/L/,  - move cursor left/right/quarter'/
     * ' caps on/off - fast/slow change in the above'//
     * '        d/D  - highlight lines with selected qn''s from',
     * ' current/all sets'/
     * '        r/R  - highlight all lines from current/',
     * 'all data sets'/
     * '        t/T  - highlight selected transition type from',
     * ' current/all sets'/
     * '        F/^  - change frequency limits/toggle window height'/
     * '      <ESC>  - refresh data (batch input only)'/
     * '        O/I  - information on displayed lines/data sets'/
     * '          G  - produce GLE output of current screen'/)
c
      if(myrows.eq.17)then
        write(*,'(15x,''Press ENTER '',$)')
631     IK=INKEY(J)
        IF(IK.NE.13)GOTO 631
        write(*,'(1x/)')
      endif
c
      WRITE(*,2321)
2321  FORMAT(
     * '          M  - stick/contour simulation display details'/
     * '          Y  - toggle addition of intensities of overlapped ',
     * 'lines'/
     * '          U  - toggle the use of different linestyles'/
     * '          P  - toggle line colouring scheme, according to',
     * ' type of transition'/15x,
     * '(reds,greens,blues for a,b,c-types), or number of data set'/
     * '          C  - toggle through overall colour schemes'//
     * '  line N/M:    stands for M unresolved lines under the cursor,'
     *  /15x,'the parameters of line N are currently displayed'/
     *  15x,'and N can be toggled with the up/down arrow keys'//
     * 15x,'Exit from the graphics is by ENTER followed by Y'/
     * 15x,'Exit from this help screen is by pressing ',$)
      DUMmy2=settextcolor(12)
      write(*,'(''ENTER '',$)')
      DUMmy2=settextcolor(ntextc)
      GOTO 107
C
C...Toggle addition of intensities of overlapping lines (with Y)
C
21    INTADD=-INTADD
      GOTO 7
C
C...Frequency limits from keyboard (with F)
C
22    dummy4=setbkcolor(ntextb)
      DUMmy2=settextcolor(ntextc)
      CALL clearscreen($GCLEARSCREEN)
      write(*,'(1x/''_____F R E Q U E N C Y   L I M I T S'',44(1H_)/)')
      WRITE(*,304)FMIN,FMAX,FMAX-FMIN,F1,F2,F2-F1,fmark
304   FORMAT(34x,'   upper       lower           range'//
     *       '  Frequency limits of data:       ',2F12.3,f16.3/
     *       '  Frequency limits of display:    ',2F12.3,f16.3/
     *       '  Frequency of cursor:            ',6x,f12.3///
     * '  Specify new display limits  1/ ENTER keeps previous value'/
     * 30x,'2/ -ve lower limit moves cursor'/
     * 30x,'3/ -ve upper limit changes range'/)
c
302   WRITE(*,300)' Lower frequency display limit:  ',F1
300   FORMAT(1X,A,F12.3,' -->  ',\)
      READ(*,'(f20.0)',ERR=302)FF1
      if(ff1.eq.0.d0)goto 303
      IF(FF1.lt.0.d0)then
        FF1=-FF1
        fmark=0.5d0*(f2-f1)
        if(ff1.gt.FMAX)ff1=FMAX-fmark
        if(ff1.lt.FMIN)ff1=FMIN+fmark
        f1=ff1-fmark
        f2=ff1+fmark 
        fmark=ff1      
        dummy4=setbkcolor(ntextb)
        CALL clearscreen($GCLEARSCREEN)
        GOTO 7
      endif
      IF(FF1.GT.FMAX)GOTO 302
      F1=FF1
c
303   WRITE(*,300)' Upper frequency display limit:  ',F2
      READ(*,'(f20.0)',ERR=303)FF2
      IF(FF2.LT.0.d0)then
        FF2=-FF2
        ff1=0.5d0*FF2
        f1=fmark-ff1
        f2=fmark+ff1
        dummy4=setbkcolor(ntextb)
        CALL clearscreen($GCLEARSCREEN)
        GOTO 7      
      ENDIF
      If(ff2.ne.0.0d0)then
        IF(FF2.LE.F1.OR.FF2.LT.FMIN)GOTO 303
        F2=FF2
      else
        if(f2.lt.f1)goto 303
      endif
      FMARK=0.5D0*(F1+F2)
      dummy4=setbkcolor(ntextb)
      CALL clearscreen($GCLEARSCREEN)
      GOTO 7
C
C
C...Change the colouring scheme for transitions (with P)
C   this can be either according to transition type
C                   or the number of the data set
C
224   LCSCHE=-LCSCHE
      CALL COLBEE(1,0,0,0,nhighc,LCSCHE)                                <-----
      GOTO 7
C
C
C...Unpublished option to toggle display of cursor information
C   (with F9 function key) - use this mode to inspect internal information
C
C   Variable LINDET which is a flag equal to either +1 or -1 - information
C   on lines underlying the cursor is only displayed for positive values.
C
24    LINDET=-LINDET
      IF(LINDET.EQ.-1)GOTO 720
C
C
C...INSPECTION CODE WHETHER THERE IS A LINE UNDERNEATH A CURSOR
C   this is executed only if LINDET=1 (ie line detection mode)
C                        and JUSTPL=1
C
C...if JUSTPL=1 then a jump straight to display for cases (such as
C   highlighting) for which the identification of overlaps has already
C   been made.
230   IF(JUSTPL.EQ.1)THEN
        JUSTPL=0
        GOTO 235
      ENDIF
C
C...Identify overlapped lines - as range of lines IFL,IFH and set the display
C   pointer JDET to the strongest line
      FL=FMARK-0.5D0*FSTEP
      FH=FMARK+0.5D0*FSTEP
      CALL HUNTF(NLINES,FL,IFL)                                         <-----
      IFL=IFL+1
      IFH=IFL
      CALL HUNTF(NLINES,FH,IFH)                                         <-----
      NLDET=IFH-IFL+1
      JDET=IFL
      IF(NLDET.GT.1)THEN
        STRONG=S(LNUM(IFL))
        DO 2231 N=IFL+1,IFH
          IF(S(LNUM(N)).GT.STRONG)THEN
            JDET=N
            STRONG=S(LNUM(N))
          ENDIF
2231    CONTINUE
      ENDIF
C
C...Write header line
235   IF(NLDET.EQ.0)THEN
        WRITE(toplin,228)FMARK,htmax
        seclin=emplin
        GOTO 722
228     FORMAT(' Cursor:',2X,F15.4,34x,'Y range = ',1PE9.2)
      ELSE
        L=LNUM(JDET)
        JD=NQ(L,1)-NQ(L,4)+2
        JKM=NQ(L,2)-NQ(L,5)
        JKP=NQ(L,3)-NQ(L,6)
        if(jd.lt.1.or.jd.gt.3)jd=4
c
        if(lcolor(l).ne.30.and.lcsche.eq.-1)then
          WRITE(toplin,229)JDET-IFL+1,NLDET,F(JDET),S(L),M(L),
     *    (NQ(L,II),II=1,6),DIPOL(L),TYPETR(JD),JKM,JKP
        else
          WRITE(toplin,1229)JDET-IFL+1,NLDET,F(JDET),S(L),M(L),
     *    (NQ(L,II),II=1,6)
        endif
229     FORMAT(' Line',I3,'/',i2,':',F13.4,1PE11.2,3X,A1,I5,2(',',I3)
     *   ,'<--',I3,2(',',I3),3X,A1,'.',A1,I2,',',I2)
1229    FORMAT(' Line',I3,'/',i2,':',F13.4,1PE11.2,3X,A1,I5,2(',',I3)
     *   ,'<--',I3,2(',',I3),11(1H ))
c
        write(seclin,1230)elow(l),(nq(l,ii),ii=7,12)
1230    format(27x,f9.3,4x,I5,2(',',I3),'<--',I3,2(',',I3))
        lincol=ncolor(L)
        GOTO 722
      ENDIF
C
C...Inspect multiple lines at cursor position (with up/down arrow keys)
C   keycodes:  -72 is UP   -80 is DOWN
C
2400  JDET=JDET+1
      IF(JDET.GT.IFH)JDET=IFL
      GOTO 235
C
2401  JDET=JDET-1
      IF(JDET.LT.IFL)JDET=IFH
      GOTO 235
C
C....Toggle BACKGROUND COLOR (with C)
C
25    BKC=BKC+1
      IF(BKC.GE.9) BKC=1
      ncursc= cursco(bkc)
      nbordc=bordco(bkc)
      nhighc=highco(bkc)
      dummy4 = setbkcolor( bkcolor(BKC) )
      dummy2=0
      goto 226
C
C....Highlight lines with selected value of one of the six quantum
C    numbers for the lower level (with d  - 'd' for current
C                                           'D' for all data sets)
C    Successive presses select successive quantum numbers out of the six
c    quantum numbers for the lower level, while the value of the quantum
c    number is defined by the current transition.
c    The seventh keypress cancels highlighting.
C
26    JUSTPL=1
      IF(DDET.EQ.6.OR.DDET.LT.0) THEN
        GOTO 226
      ELSE
        DDET=DDET+1
        L=LNUM(JDET)
        IF(DDET.GT.1 .AND. FCDET.NE.F(JDET)) GOTO 226
        IF(DDET.EQ.1) THEN
          CDDET=NCOLOR(L)
          FCDET=F(JDET)
        ENDIF
        dddet=(ddet/4+1)*3+ddet
        JCDET=NQ(L,dDDET)
        DUMSET=SET(L)
        IF(KK.EQ.'D')DUMSET=-1
        CALL COLBEE(DUMSET,0,   0,    0,nhighc,LCSCHE)                  <-----
        CALL COLBEE(DUMSET,0,DDET,JCDET,nhighc,LCSCHE)                  <-----
      ENDIF
      GOTO 7
C
C...clear highlighting - reset standard colours
226   CALL COLBEE(1,0,0,0,nhighc,LCSCHE)                                <-----
      DDET=0
      GOTO 7
C
C...Highlight selected data set (with R -  'r' current
C                                          'R' all data sets)
C    current data set defined by the line currently or most recently
C    underneath the cursor )
C
27    JUSTPL=1
      IF(DDET.LT.0)GOTO 226
      DDET=-1
      DUMSET=SET(L)
      IF(KK.EQ.'R')DUMSET=-1
      CALL COLBEE(DUMSET,0,   0, 0,nhighc,LCSCHE)                       <-----
      CALL COLBEE(DUMSET,0,DDET, 0,nhighc,LCSCHE)                       <-----
      GOTO 7
C
C...Highlight selected transition type (with T -  't' in current,
C                                                 'T' in all data sets)
C    current data set is defined by the line currently or most recently
C    underneath the cursor
C
29    DUMMY2=0
      JUSTPL=1
      IF(DDET.LT.0)GOTO 226
      DDET=-2
      DUMSET=SET(L)
      IF(KK.EQ.'T')DUMSET=-1
      JD=(NQ(L,1)-NQ(L,4))*100+(NQ(L,2)-NQ(L,5))*10
     *  +(NQ(L,3)-NQ(L,6))
      CALL COLBEE(DUMSET, 0,   0, 0,nhighc,LCSCHE)                      <-----
      CALL COLBEE(DUMSET,JD,DDET, 0,nhighc,LCSCHE)                      <-----
      GOTO 7
C
C...Display information on data sets (with I)
C
28    continue
      dummy4=setbkcolor(ntextb)
      DUMmy2=settextcolor(ntextc)
      CALL clearscreen($GCLEARSCREEN)
      WRITE(*,283)
283   FORMAT(1x/'_____L O A D E D   D A T A',54(1H_)///
     *       13X,'Relative    No of   Line    Name '/
     *       13X,'intensity   lines   style'/
     *       11X,' ',59(1H_),' ')
      DO 284 J=1,NLSET
        IF(J.LT.10)KK=CHAR(48+J)
        IF(J.GT.9)KK=CHAR(55+J)
        WRITE(*,285)kk,RELati(j),INFSET(J,3),INFSET(J,2),SETNAM(J)
284   CONTINUE
285   FORMAT(5X,'Set ',a,': ',F10.5,I8,I6,5X,A30,' ')
C
      WRITE(*,281)NLINES
281   FORMAT(11x,' ',59(1HŻ),' '/5X,'Total ',10x,I9,$)
      DUMmy2=settextcolor(12)
      write(*,'(18x,a,$)')'Press ENTER to continue'
      DUMmy2=settextcolor(ntextc)
282   IK=INKEY(J)
      IF(IK.EQ.0)GOTO 282
      dummy4=setbkcolor(ntextb)
      CALL clearscreen($GCLEARSCREEN)
      GOTO 7
C
c...GLE output (with G)
c
30    dummy4=setbkcolor(ntextb)
      DUMmy2=settextcolor(ntextc)
      CALL clearscreen($GCLEARSCREEN)
      call gleout(f1,f2,RM,RLARGE,sshift,istico)                        <-----
      dummy4=setbkcolor(ntextb)
      CALL clearscreen($GCLEARSCREEN)
      GOTO 7
C
C..Display mode - stick or contour or stick+contour (with M)
C
31    dummy4=setbkcolor(ntextb)
      DUMmy2=settextcolor(ntextc)
      call stispe(F1,F2,HWHH,dopspl,istico,ICTYP,ICDER)                 <-----
      dummy4=setbkcolor(ntextb)
      CALL clearscreen($GCLEARSCREEN)
      goto 7
C
100   RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE stispe(F1,F2,HWHH,dopspl,istico,ICTYP,ICDER)
c
C    To modify control parameters for the screen display mode:
c
C         F1 = lower frequency limit of current plot
C         F2 = upper frequency limit of current plot
C     istico = 0 stick mode
C            = 1 contour simulation mode
C            = 2 contour simulation + sticks
C      ictyp = 0 Gaussian lineshape
C            = 1 Lorentzian lineshape
C      icder = 0 natural lineshape
C            = 1 first derivative
C            = 2 second derivative
C       HWHH = half width at half height (for natural lineshape)
C     dopspl = Doppler splitting frequency for doubled lines
C      
C      
      USE DFLIB
c
      implicit real*8 (a-h,o-z)
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1, MAXNSP=50000)
      REAL*8 SPEC(MAXNSP)
      INTEGER*2 DUMMY2,inkey      
      character iptype(3)*14,iltype(3)*10,ilder(3)*6
      COMMON /COMSPE/SPEC,NSPEC
c
      data iptype/'Sticks','Contour','Contour+Sticks'/
      data iltype/'Gaussian','Lorentzian','Voigt'/
      data ilder/'None','First','Second'/
      if(nspec.le.0)nspec=2000
c
c...OPTIONS
c
c
59    call clearscreen($GCLEARSCREEN)
      WRITE(*,56)
56    FORMAT(1x/'_____D i s p l a y   M o d e   C o n t r o l',36(1H_)
     * //)
c
58    FSTEP=(F2-F1)/NSPEC
      WRITE(*,57)iptype(istico+1),iltype(ictyp+1),ilder(icder+1),HWHH,
     * dopspl,NSPEC,FSTEP
57    FORMAT(1x/
     * '      1:             Type of plot =  ',a/
     * '      2:       Lineshape function =  ',a/
     * '      3:               Derivative =  ',a/
     * '      4:                     HWHH =  ',f10.4/
     * '      5:         Doppler doubling =  ',f10.4/
     * '      6: Number of contour points = ',i6,6x,'<-- currently',
     *  F8.3,' fr.units'/69x,'per point'//
     * '      Select 1-6 (ENTER=OK) .....  ',$)
C
      READ(*,'(I2)',err=59)I
      if(i.lt.0.or.i.gt.6)goto 59
c
      if(i.eq.1)then
        write(*,'(1x//'' Select type of plot:   0 = sticks''/
     *    24x,''1 = simulated contour''/
     *    24x,''2 = contour + sticks''//24x,''..... '',$)')
        read(*,'(i2)',err=59)n
        if(n.lt.0.or.n.gt.2)goto 59
        istico=n
        goto 59
      endif
c
      if(i.eq.2)then
        write(*,'(1x//'' Select lineshape function:''//
     *    24x,''0 = Gaussian''/24x,''1 = Lorentzian''//
     *    24x,''.....  '',$)')
        read(*,'(i2)',err=59)n
        if(n.lt.0.or.n.gt.1)goto 59
        ictyp=n
        goto 59
      endif
c
      if(i.eq.3)then
        write(*,'(1x//'' Select derivative order:''//
     *    24x,''0 = Natural lineshape''/24x,''1 = First derivative''/
     *    24x,''2 = Second derivative''//24x,''.....  '',$)')
        read(*,'(i2)',err=59)n
        if(n.lt.0.or.n.gt.2)goto 59
        icder=n
        goto 59
      endif
c
      if(i.eq.4)then
        write(*,'(1x// 
     *    6x,''Halfwidth = HWHH as defined for the natural lineshape''//
     *   18x,''NOTE that a -ve value can be used to specify HWHH as''/
     *   18x,''a Doppler shift in km/s, in which case frequency is ''/
     *   18x,''assumed to be in MHz''///
     *    6x,''New halfwidth = '',$)')
        read(*,'(F20.10)',err=59)temp
        if(temp.lt.-500000.d0)goto 59
        if(temp.eq.0.d0)goto 59
        if(temp.gt.500000.d0)goto 59
        HWHH=temp
        goto 59
      endif
c
      if(i.eq.5)then
        write(*,'(1x// 
     *    6x,''New Doppler doubling frequency = '',$)')
        read(*,*,err=59)temp
        if(temp.lt.0.d0)goto 59
        if(temp.gt.500000.d0)goto 59
        dopspl=temp
        goto 59
      endif
c
      if(i.eq.6)then
        write(*,'(1x//
     *    ''      New number of points for the simulated contour = ''
     *    ,$)')
        read(*,'(i10)',err=59)itemp
        nspec=itemp
        if(itemp.gt.maxnsp)then
          nspec=maxnsp
          DUMmy2=settextcolor(12)
          write(*,'(1x//
     *       ''      Only up to'',i7,'' points are currently allowed''
     *       /)')maxnsp
          DUMmy2=settextcolor(ntextc)
          write(*,'(1x/''      Press ENTER  '',$)')
107       IK=INKEY(dummy2)
          IF(IK.EQ.0)GOTO 107
          IF(IK.EQ.13)goto 59
        endif     
        if(itemp.lt.10)then
          nspec=10
          DUMmy2=settextcolor(12)
          write(*,'(1x//
     *       i8,'' is a ridiculous number of points''/)')itemp
          DUMmy2=settextcolor(ntextc)
          write(*,'(1x/''      Press ENTER  '',$)')
108       IK=INKEY(dummy2)
          IF(IK.EQ.0)GOTO 108
          IF(IK.EQ.13)goto 59
        endif
        goto 59
      endif
c
c
52    RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE GLEOUT(F1,F2,RM,RLARGE,sshift,istico)
C
C    To produce .GLE and associated .DAT files for the current display.
C    Features:
C          - separate .DAT files for datasets which have lines on screen
C          - linetypes of data sets reproduced
C          - if any lines are highlighted then they are in continuous linetype,
C            while all other lines are drawn dotted
C          - plot is only for the NOT ADDED intensities and colour is not
C            preserved
C
C     F1 - lower frequency limit
C     F2 - upper frequency limit
C RLARGE - Y-axis maximum
C     RM - marker spacing
C SSHIFT - Y-axis shift for simulated spectrum (if any)
C istico - plot control: sticks only (0), simulated contour (1), 
C          sticks+contour (2)
C
C
      USE DFLIB
C
      PARAMETER (MAXLIN=100000,MAXFIL=20,MAXNSP=50000)
      PARAMETER (ntextc=0, ntextb=7)
C
      REAL*4 S(MAXLIN),SMAX,ELOW(maxlin)
      REAL*8 F(MAXLIN),FMIN,FMAX,F1,F2,RM,RLARGE,tenm,ftenm,
     *       SPEC(MAXNSP),FSTEP,freq,sshift,fmult,ysmax,ysmin
      INTEGER*1 SET(MAXLIN),LST(MAXLIN),NCOLOR(MAXLIN),LCOLOR(MAXLIN),
     *          iflag(maxfil)
      CHARACTER SETNAM(maxfil)*30,setnm(maxfil)*20,maxabs*9
      CHARACTER numset*2,filout*60,filgen*6,filcon*60,gener*50
      character*127 marlin
      INTEGER*4 INFSET(maxfil,3),lnum(maxlin)
      COMMON  /FRBLK/F
     *         /SBLK/FMIN,FMAX,ELOW,S,SMAX,NLINES
      COMMON /ORIGLN/SET,LST,NLSET,NCOLOR,LCOLOR
      COMMON /SETINF/INFSET,SETNAM,SETNM,gener
      COMMON  /LNUMS/LNUM
      COMMON /COMSPE/SPEC,NSPEC
      INTEGER*2 lstyle(10)
      integer*2 tday,tmon,tyear,thour,tmin,tsec,t100
C
C   For visually similar linestyles the running lengths declared in STICKS have
C   to be halved 
C
C code in STICKS: 80,  55,  22,9222,  26,  99,6424,  82,4248,2224       
C
      data lstyle/ 1,  33,  11,5111,  13,  55,3212,  41,2124,1112/
C
      base=-.1
      maxlab=5
      ilight=0
C
C...scale output down by 1000, i.e. plot GHz and not MHz for THz values
C
      if(f2.gt.1000000.D0)then
        fmult=0.001D0
      else
        fmult=1.d0
      endif      
      call getdat(tyear,tmon,tday)
      call gettim(thour,tmin,tsec,t100)
C
C...determine generic file name
C
      WRITE(*,56)
56    FORMAT(1x/'_____g l e   O U T P U T',56(1H_)///5x,
     * 'of the spectrum as limited by the the current viewport,'/5x,
     * 'and only in the NOT ADDED display version'/ )
c
      dummy=displaycursor($gcursoron)
21    write(*,20)
20    format(1x/5x,
     *  'Up to six character generic file name for GLE output:'//
     *  25x,'....  ',$)
      read(*,'(a)',err=21)filgen
      do 14 nc=6,1,-1
        if(filgen(nc:nc).ne.' ')goto 15
14    continue
C
C...establish which data files have to be used and whether there is
C   highlighting
C
15    do 10 nset=1,nlset
        iflag(nset)=0
10    continue
      do 11 ncount=1,nlines
        if(f(ncount).lt.f1)goto 11
        if(f(ncount).gt.f2)goto 12
        n=lnum(ncount)
        nset=set(n)
        iflag(nset)=1
        if(ncolor(n).eq.15.or.ncolor(n).eq.0.or.ncolor(n).eq.1
     *                    .or.ncolor(n).eq.5)ilight=1
11    continue
c
c
c...Write the control .GLE file
c
12    if(len_trim(gener).lt.1)gener='.\'
      filout=gener(1:len_trim(gener))//filgen(1:nc)//'.gle'
      open(3,file=filout,status='unknown',err=21)
      dummy=displaycursor($gcursoroff)
      filcon=filout
      write(3,7)thour,':',tmin,':',tsec,tday,'/',tmon,'/',tyear
7     format('!',70(1H-)/'!'/'!   Diagram from ASCP,  generated'
     *   i4,a,i2,a,i2,i3,a,i2,a,i4/'!'/
     * '!',70(1H-)/'!')
c
      write(3,'(a)')'size 29.5 21'
      write(3,'(a)')'set lwidth 0.030'
      write(3,'(a)')'set join round'
      write(3,'(a)')'amove  -5. 4.'
      write(3,'(a)')'begin graph'
      write(3,'(a)')'    nobox'
      write(3,'(a)')'    size 37.5 17'
      write(3,'(a,f10.2,a,F10.2,a,F9.2,a,F9.3)')
     * '    xaxis  min ',F1*fmult,' max ',F2*fmult,' dticks ',
     *  10.d0*RM*fmult,' dsubticks ',RM*fmult
      write(3,'(a)')'    xlabels             hei 0.7'
      write(3,'(a)')'    xticks length -0.4'
      write(3,'(a)')'    xsubticks length -0.15'
      write(3,'(a)')'    x2ticks off'
      write(3,'(a,F15.10)')'    yaxis min 0.00 max',RLARGE
      write(3,'(a)')'    yticks off'
      write(3,'(a)')'    ylabels off'
c
c...sticks
c
      if(istico.ne.1)then
        if(ilight.eq.0)then
          do 5 nset=1,nlset
            if(iflag(nset).eq.0)goto 5
            write(3,'(''!''/''!   sticks from  '',a/''!'')')setnam(nset)
            write(numset,'(i2)')nset
            if(nset.lt.10)then
              numset=numset(2:2)
              filout=
     *          filgen(1:nc)//numset(1:1)//'.dat'
            else
              filout=
     *          filgen(1:nc)//numset//'.dat'
            endif
            write(3,'(4a)')'    d',numset,' bigfile ',filout
            write(3,'(a,a,a,i4,a,a)')
     *        '    d',numset,' lstyle ',lstyle(infset(nset,2)),
     *        ' color black lwidth 0.025'
5         continue
        else
          write(3,'(''!''/''!   highlighted lines  ''/''!'')')
          filout=filgen(1:nc)//'1.dat'
          write(3,'(2a)')'    d1 bigfile ',filout
          write(3,'(a)')'    d1 lstyle 1 color black lwidth 0.025'
          write(3,'(''!''/''!   remaining lines  ''/''!'')')
          filout=filgen(1:nc)//'2.dat'
          write(3,'(2a)')'    d2 bigfile ',filout
          write(3,'(a)')'    d2 lstyle 12 color black lwidth 0.025'
        endif
      endif
c
c..simulation
c
      if(istico.ne.0)then
        do 405 nset=1,nlset
          if(nset.eq.1)
     *      write(3,'(''!''/''!   simulated spectrum from  '',a)')
     *      setnam(nset)
          if(nset.gt.1)
     *      write(3,'(''!'',28x,a)')setnam(nset)
405     continue
        write(3,'(1H!)')
c              
        write(numset,'(i2)')nlset+1
        if(nset.lt.10)numset=numset(2:2)
        filout=filgen(1:nc)//'s.dat'
        write(3,'(4a)')'    d',numset,' bigfile ',filout
        write(3,'(a,a,a,i4,a,a)')
     *    '    d',numset,' lstyle ',lstyle(infset(nset,2)),
     *    ' color black lwidth 0.025'       
      endif
c
c...markers, if necessary deal with too many marker labels
c
      tenm=rm*10.d0
      ftenm=dint(f1/tenm)*tenm
      if(ftenm.lt.f1)ftenm=ftenm+tenm
c
      if(dint((f2-f1)/tenm).gt.real(maxlab))then
c
        write(3,'(a)')'!'
        write(marlin(1:9),'(a)')' xplaces '
        marind=10
22      if(tenm.lt.0.01d0)
     *    write(marlin(marind:marind+8),'(f9.3)',err=25)ftenm*fmult
        if(tenm.lt.0.1d0.and.tenm.ge.0.01d0)
     *    write(marlin(marind:marind+8),'(f9.2)',err=25)ftenm*fmult
        if(tenm.lt.1.d0 .and.tenm.ge.0.1d0)
     *    write(marlin(marind:marind+8),'(f9.1)',err=25)ftenm*fmult       
        if(tenm.ge.1.d0)then
          if(fmult.gt.0.99d0)then
            write(marlin(marind:marind+8),'(i9)',err=25)
     *         nint(ftenm*fmult)
          else
            if(tenm.lt.10.d0 .and.tenm.ge.1.d0)
     *         write(marlin(marind:marind+8),'(f9.3)',err=25)ftenm*fmult       
            if(tenm.lt.100.d0 .and.tenm.ge.10.d0)
     *         write(marlin(marind:marind+8),'(f9.2)',err=25)ftenm*fmult       
            if(tenm.lt.1000.d0 .and.tenm.ge.100.d0)
     *         write(marlin(marind:marind+8),'(f9.1)',err=25)ftenm*fmult       
            if(                    tenm.ge.1000.d0)
     *         write(marlin(marind:marind+8),'(i9)',err=25)
     *         nint(ftenm*fmult)    
          endif
        endif
        marind=marind+9
        if(marlin(marind-9:marind-9).ne.' ')then
          if(marind.le.127)marlin(marind:marind)=' '
          marind=marind+1
        endif
        ftenm=ftenm+tenm
        if(ftenm.lt.f2.and.marind.lt.119)then
          goto 22
        else
          write(3,'(a)')marlin(1:marind-1)
        endif
c
        write(marlin(1:8),'(a)')' xnames '
        marind=9
        ftenm=dint(f1/tenm)*tenm
        if(ftenm.lt.f1)ftenm=ftenm+tenm
        if(dint(ftenm/(2.d0*tenm))*2.d0*tenm.ne.ftenm)then
          write(marlin(marind:marind+4),'(a)')' " " '
          marind=marind+5
          ftenm=ftenm+tenm
        endif
23      if(tenm.lt.0.01d0)
     *    write(marlin(marind:marind+10),'(a,f9.3,a)',err=25)
     *    '"',ftenm*fmult,'"'
        if(tenm.lt.0.1d0.and.tenm.ge.0.01d0)
     *    write(marlin(marind:marind+10),'(a,f9.2,a)',err=25)
     *    '"',ftenm*fmult,'"'
        if(tenm.lt.1.d0 .and.tenm.ge.0.1d0)
     *    write(marlin(marind:marind+10),'(a,f9.1,a)',err=25)
     *    '"',ftenm*fmult,'"'
        if(tenm.ge.1.d0)then
          if(fmult.gt.0.99d0)then
            write(marlin(marind:marind+10),'(a,i9,a)',err=25)
     *      '"',nint(ftenm*fmult),'"'
          else
            if(tenm.lt.10.d0 .and.tenm.ge.1.d0)
     *        write(marlin(marind:marind+10),'(a,f9.3,a)',err=25)
     *        '"',ftenm*fmult,'"'
            if(tenm.lt.100.d0 .and.tenm.ge.10.d0)
     *        write(marlin(marind:marind+10),'(a,f9.2,a)',err=25)
     *        '"',ftenm*fmult,'"'
            if(tenm.lt.1000.d0 .and.tenm.ge.100.d0)
     *        write(marlin(marind:marind+10),'(a,f9.1,a)',err=25)
     *        '"',ftenm*fmult,'"'
            if(tenm.ge.1000.d0                    )
     *        write(marlin(marind:marind+10),'(a,i9,a)',err=25)
     *        '"',nint(ftenm*fmult),'"'
          endif
        endif
        marind=marind+11
        if(marind+4.le.127)
     *      write(marlin(marind:marind+4),'(a)',err=25)' " " '
        marind=marind+5
        ftenm=ftenm+2.d0*tenm
        if(ftenm.lt.f2.and.marind.lt.117)then
          goto 23
        else
          write(3,'(a)')marlin(1:marind-1)
          write(3,'(a)')'!'
        endif
c
      endif
c
      goto 26
25    write(3,27)
27    format('!'/'! SORRY - Could not generate xnames/xplaces lines'/
     * '!')
c
26    write(3,'(a)')'end graph'
c
c...legend lines
c
      if(ilight.eq.0)then
        write(3,'(1x/a)')'set hei 0.5'
        n=0
        do 40 nset=1,nlset
          if(iflag(nset).eq.0)goto 40
          n=n+1
          if(((n-1)/3)*3.eq.(n-1))then
            x=x+7.0
            y=4.0
          else
            y=y-0.7d0
          endif
          if(n.eq.1)x=0.7d0
          do 42 i=1,30
            if(setnam(nset)(i:i).eq.'\')setnam(nset)(i:i)='/'
42        continue
          if(n.le.12)write(3,41)'set lstyle ',lstyle(infset(nset,2)),
     *                'amove ',x,y,'rline 1 0','rmove 0.5 -0.175',
     *                'set lstyle 1','text ',setnm(nset)
40      continue
41      format(1x/a,i4/a,2f10.5/a/a/a/2a)
      endif
c
      write(3,'(1x/a/a//a/a/a//a/a/a//a/a//a/a//a/a//a)')
     *     '! set font texcmr','set hei 0.7','set color grey30',
     *     'amove 0.65 20.25','text {\bf ASCP}','set color grey10',
     *     'amove 0.64 20.26','text {\bf ASCP}','amove 0.63 20.27',
     *     'text {\bf ASCP}','amove 0.62 20.28','text {\bf ASCP}',
     *     'amove 0.61 20.29','text {\bf ASCP}','set color black'
      write(3,'(a/a,i2,a,i2,a,i2,a,i2,a,i2,a,i4,a)')
     * 'amove 0.6 20.3',
     * 'text {\bf ASCP}_{\,',thour,':',tmin,':',tsec,' \,'
     *                      ,tday,'/',tmon,'/',tyear,'}'
c
      write(maxabs,'(1PE9.2)')rlarge
	write(3,'(1x/a/a/a)')'set hei 0.4',
     *                     'amove 20.5 18.8','set font texcmss'
      if(maxabs(8:8).ne.'0')then
	  write(3,'(1x,7a)')
     *    'text {\rm Maximum intensity = ',maxabs(2:5),
     *    '} x {\rm10^{\tt',maxabs(7:7),'\rm',maxabs(8:9),
     *    '} cm^{\tt-\rm1}}'
      else
	  write(3,'(1x,7a)')
     *    'text {\rm Maximum intensity = ',maxabs(2:5),
     *    '} x {\rm10^{\tt',maxabs(7:7),'\rm',maxabs(9:9),
     *    '} cm^{\tt-\rm1}}'
	endif
	write(3,'(a)')'set font texcmr'
c
      write(3,'(12(a/),a)')'!','! uncomment as necessary','!',
     * '! set font texcmr','set hei 0.7','amove 0.6 5.3',
     * '! text MHz','! text GHz','! text cm^{-1}','amove 25.4 5.3',
     * '! text MHz','! text GHz','! text cm^{-1}'
      write(3,'(1h!/2(1H!,70(1h-)/))')
      close(3)
      write(*,'(1x/5x,a,$)')' Control file written to  '
      dummy=settextcolor(12)
      write(*,'(a)')filcon(1:len_trim(filcon))
      dummy=settextcolor(ntextc)
c
c...write the .DAT file or files for sticks
c
      if(istico.ne.1)then
        if(ilight.eq.0)then
          do 8 nset=1,nlset
            if(iflag(nset).eq.0)goto 8
            write(numset,'(i2)')nset
            if(nset.lt.10)then
              numset=numset(2:2)
              filout=
     *       gener(1:len_trim(gener))//filgen(1:nc)//numset(1:1)//'.dat'
            else
              filout=
     *         gener(1:len_trim(gener))//filgen(1:nc)//numset//'.dat'
            endif
            open(4,file=filout,status='unknown')
            write(4,7)thour,':',tmin,':',tsec,tday,'/',tmon,'/',tyear
            write(4,'(''!   Sticks from data in file:  '',a/1h!)')
     *            setnam(nset)
            ncount=0
1           ncount=ncount+1
              if(ncount.gt.nlines)goto 2
              if(f(ncount).lt.f1)goto 1
              if(f(ncount).gt.f2)goto 2
              n=lnum(ncount)
              if(set(n).ne.nset)goto 1
              write(4,4)f(ncount)*fmult,base
              write(4,4)f(ncount)*fmult,s(n)
              write(4,'(f13.4,a)')f(ncount)*fmult,'    *'
4             format(F13.4,1PE11.3)
            goto 1
2           write(4,'(2(''!'',70(1H-)/))')
            close(4)
            write(*,'(5x,a,$)')'  Subset data written to  '
            dummy=settextcolor(12)
            write(*,'(a)')filout(1:len_trim(filout))
            dummy=settextcolor(ntextc)
8         continue
        else
          filout=gener(1:len_trim(gener))//filgen(1:nc)//'1.dat'
          open(4,file=filout,status='unknown')
          write(4,7)thour,':',tmin,':',tsec,tday,'/',tmon,'/',tyear
          write(4,'(a/1h!)')'!    Highlighed lines'
          do 30 n=1,nlines
            if(f(n).lt.f1)goto 30
            if(f(n).gt.f2)goto 31
            nn=lnum(n)
            if(ncolor(nn).ne.15)goto 30
            write(4,4)f(n)*fmult,base
            write(4,4)f(n)*fmult,s(nn)
            write(4,'(f13.4,a)')f(n)*fmult,'    *'
30        continue
31        write(4,'(2(''!'',70(1H-)/))')
          close(4)
          write(*,'(1x,a,$)')'Highlighted lines written to  '
          dummy=settextcolor(12)
          write(*,'(a)')filout(1:len_trim(filout))
          dummy=settextcolor(ntextc)
          filout=gener(1:len_trim(gener))//filgen(1:nc)//'2.dat'
          open(4,file=filout,status='unknown')
          write(4,7)thour,':',tmin,':',tsec,tday,'/',tmon,'/',tyear
          write(4,'(a/1h!)')'!    Lines which are not highlighted'
          do 33 n=1,nlines
            if(f(n).lt.f1)goto 33
            if(f(n).gt.f2)goto 34
            nn=lnum(n)
            if(ncolor(nn).eq.15)goto 33
            write(4,4)f(n)*fmult,base
            write(4,4)f(n)*fmult,s(nn)
            write(4,'(f13.4,a)')f(n)*fmult,'    *'
33        continue
34        write(4,'(2(''!'',70(1H-)/))')
          close(4)
          write(*,'(3x,a,$)')'Remaining lines written to  '
          dummy=settextcolor(12)
          write(*,'(a)')filout(1:len_trim(filout))
          dummy=settextcolor(ntextc)
        endif
      endif
c
c...DAT file for the simulated spectrum
c
      if(istico.ne.0)then
        filout= gener(1:len_trim(gener))//filgen(1:nc)//'s.dat'
        open(4,file=filout,status='unknown')
        write(4,7)thour,':',tmin,':',tsec,tday,'/',tmon,'/',tyear
        do 400 nset=1,nlset
          if(nset.eq.1)
     *       write(4,'(''!   simulated spectrum from data in:  '',a)')
     *          setnam(nset)
          if(nset.gt.1)write(4,'(''!'',37x,a)')setnam(nset)
400     continue
        write(4,'(1H!)')
        ysmax=1.d-30
	  ysmin=1.d+30
        do 410 n=1,nspec
          if(spec(n).gt.ysmax)ysmax=spec(n)
	    if(spec(n).lt.ysmin)ysmin=spec(n)
410     continue        
	  write(4,409)'! Y.range    ',ysmax-ysmin
409     format(a,1PE12.4)
        write(4,'(1H!)')
        fstep=(F2-F1)/real(nspec)
        freq=F1-fstep
        do 401 n=1,nspec
          freq=freq+fstep
          write(4,402)freq*fmult,spec(n)+sshift
401     continue        
402     format(f13.4,1PE12.4)
        write(4,'(''!'',70(1H-)/''!'',70(1H-))')
        close(4)
        write(*,'(a,$)')'Simulated spectrum written to  '
        dummy=settextcolor(12)
        write(*,'(a)')filout(1:len_trim(filout))
        dummy=settextcolor(ntextc)
      endif
c
      WRITE(*,'(1x/25x,
     *   ''f i n i s h e d,   Press ENTER to continue'')')
200   ik=inkey(int2(n))
      if(ik.ne.13)goto 200
c
      RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE PLOSPE(F1,F2,HT,YSTEP,sshift,hwhhd,dopspl,ictyp,icder)
C
C   Calculate and plot the simulated spectrum:
C
C     F1,F2 - frequency limits for plot
C        HT - Y-axis maximum for plot
C     YSTEP - Y-axis resolution per pixel
C    SSHIFT - Y-axis shift for plotted contour
C     HWHHD - half width at half-height for line simulation (-ve value
C             means km/s and frequency is then assumed to be in MHz)
C    DOPSPL - Doppler splitting for doubled lines
C     ICTYP - type of lineshape
C     ICDER - order of lineshape derivative
C
      USE DFLIB
C
      IMPLICIT REAL*8(A-H,O-Z)
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
C
      REAL*8 LNHALF
      PARAMETER (MAXLIN=100000,MAXNSP=50000,LNHALF=-0.6931471806D0)
C
      INTEGER*2 maxx,maxy,mymode,myrows,mycols,linofs
      INTEGER*4 LNUM(MAXLIN)
      REAL*8 SPEC(maxnsp),F(MAXLIN)
      REAL*4 S(MAXLIN),ELOW(MAXLIN),SMAX
      CHARACTER M(MAXLIN)
C
      COMMON /limits/wxy,maxx,maxy,LINOFS,curpos,ixy,
     * mymode,myrows,mycols
      COMMON /LNUMS/LNUM/DOUBL/M
      COMMON /FRBLK/F
      COMMON /SBLK/FMIN,FMAX,ELOW,S,SMAX,NLINES
      COMMON /COMSPE/SPEC,NSPEC   
C
      YSHIFT=-5.d0*ystep
      FSTEP=(F2-F1)/REAL(NSPEC)
      FSPL=DOPSPL*0.5d0
C
C
C...Determine line range for coadding
C
      if(hwhhd.gt.0.0d0)then
        HWHH=HWHHD
      else
        HWHH=F2*abs(HWHHD)/3.d5
      endif
C      
C...Gaussian
      if(ictyp.eq.0)then
        if(icder.eq.0)fcut= 5.d0*HWHH + fspl
        if(icder.eq.1)fcut= 5.d0*HWHH + fspl
        if(icder.eq.2)fcut= 5.d0*HWHH + fspl
      endif
c
c...Lorentzian
      if(ictyp.eq.1)then
        if(icder.eq.0)fcut=80.d0*HWHH + fspl
        if(icder.eq.1)fcut=60.d0*HWHH + fspl
        if(icder.eq.2)fcut=40.d0*HWHH + fspl
      endif
c              
      first=f1-fcut
      flast=f2+fcut
      DO 12 n=1,NLINES
        if(f(n).ge.first)then
          ifirst=n
          goto 14
        endif
12    continue
      ifirst=nlines
c
14    do 5 n=ifirst,nlines
        if(F(n).ge.flast)then
          ilast=n
          goto 17
        endif
5     continue      
      ilast=nlines
C
C
C...CALCULATE THE SPECTRUM
C
17    DO  4 I=1,NSPEC
        if(icder.eq.0)SPEC(I)=0.15d0*HT
        if(icder.eq.1)SPEC(I)=0.50D0*HT
        if(icder.eq.2)SPEC(I)=0.30d0*HT
4     CONTINUE
C
C...GO THROUGH THE LINES IN TURN. The lineshape formulae in use are 
C   unity normalised, so that multiplication by the HEIGHT
C   parameter gives the same intensity as for the plotted sticks.
C
C   For second derivatives the phase is reversed to get the positive 
C   central peak.
C
      HWHH=HWHHD
      HWSQ=HWHH*HWHH
      DO 16 N=ifirst,ilast
          flowc=f(n)-fcut
          ftopc=f(n)+fcut
          HEIGHT=S(lnum(n))
          if(M(lnum(n)).eq.'D')HEIGHT=HEIGHT*2.D0
c
          if(hwhhd.lt.0.d0)then
            HWHH=F(n)*abs(HWHHD)/3.d5
            HWSQ=HWHH*HWHH
          endif
C
          if(ictyp.eq.0)then
            if(icder.eq.1)HEIGHT=HEIGHT*HWHH/0.714135278D0
            if(icder.eq.2)HEIGHT=HEIGHT*HWSQ/1.386294361d0
          endif          
          if(ictyp.eq.1)then
            if(icder.eq.1)HEIGHT=HEIGHT*HWHH/0.649519053D0
            if(icder.eq.2)HEIGHT=HEIGHT*HWSQ/2.d0
          endif          
C
          Freq=F1-Fstep    
          DO 15 I=1,NSPEC
            Freq=Freq+FSTEP
            if(freq.lt.flowc)goto 15
            if(freq.gt.ftopc)goto 16
            if(dopspl.eq.0.d0)then
              FF=(F(N)-freq)
            else
              FF =(F(N)-freq-fspl)
              FFA=(F(N)-freq+fspl)
            endif
C
C...Gaussian
C
            if(ictyp.eq.0)then
              IF(icder.eq.0)then
                SPEC(I)=SPEC(I)+HEIGHT*dexp(LNHALF*FF**2/HWSQ)
                if(dopspl.ne.0.d0)
     *            SPEC(I)=SPEC(I)+HEIGHT*dexp(LNHALF*FFA**2/HWSQ)  
              endif
C
              IF(icder.eq.1)then
                SPEC(I)=SPEC(I)-(2.d0*lnhalf*FF*HEIGHT/HWSQ)
     *                  *dexp(LNHALF*FF**2/HWSQ)
                if(dopspl.ne.0.d0)
     *             SPEC(I)=SPEC(I)-(2.d0*lnhalf*FFA*HEIGHT/HWSQ)
     *                    *dexp(LNHALF*FFA**2/HWSQ)
              endif
C
              IF(icder.eq.2)then
                SPEC(I)=SPEC(I)-(2.d0*LNHALF*HEIGHT/HWSQ)
     *                  *dexp(LNHALF*FF**2/HWSQ)
     *                  *(1.d0+2.d0*FF*FF*lnhalf/hwsq)               
                if(dopspl.ne.0.d0)
     *             SPEC(I)=SPEC(I)-(2.d0*LNHALF*HEIGHT/HWSQ)
     *                    *dexp(LNHALF*FFA**2/HWSQ)
     *                    *(1.d0+2.d0*FFA*FFA*lnhalf/hwsq)               
              endif
            endif
c
c...Lorentzian
c
            IF(ictyp.eq.1)then
              IF(icder.eq.0)then
                SPEC(I)=SPEC(I)+HEIGHT*HWSQ/(FF*FF+HWSQ)
                if(dopspl.ne.0.d0)
     *             SPEC(I)=SPEC(I)+HEIGHT*HWSQ/(FFA*FFA+HWSQ)
              endif
c
              IF(icder.eq.1)then
                SPEC(I)=SPEC(I)+2.d0*HEIGHT*HWSQ*FF/(HWSQ+FF*FF)**2
                if(dopspl.ne.0.d0)
     *            SPEC(I)=SPEC(I)+2.d0*HEIGHT*HWSQ*FFA/(HWSQ+FFA*FFA)**2
              endif
c
              IF(icder.eq.2)then           
                FFSQ=FF*FF
                SPEC(I)=SPEC(I)+2.d0*HEIGHT*HWSQ*(HWSQ-3.d0*FFSQ)/
     *                        (HWSQ+FFSQ)**3
                if(dopspl.ne.0.d0)then
                  FFSQ=FFA*FFA
                  SPEC(I)=SPEC(I)+2.d0*HEIGHT*HWSQ*(HWSQ-3.d0*FFSQ)/
     *                        (HWSQ+FFSQ)**3
                endif
              endif
            endif
15        CONTINUE
C
16    CONTINUE
C
C...Plot the spectrum
C
      DO 100 I=1,nspec
        RSPEC=spec(i)+sshift
        IF(RSPEC.gt.ht)rspec=ht
        if(rspec.lt.yshift)rspec=yshift
        if(i.eq.1)then           
          fpoint=F1
          CALL moveto_w(fpoint,rspec,wxy)
        else
          fpoint=fpoint+fstep
          dummy=lineto_w(fpoint,RSPEC)
        endif
100   CONTINUE
C
      RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE STICKS(F1,F2,FSTEP,RM,HT,YSTEP,INTADD,LSTYLS,LCSCHE,
     *                  itxt,bkcol,nbordc,istico)
C
C   PLOT STICK DIAGRAM OF THE DATA:
C       F1,F2 - frequency limits
C       FSTEP - frequency step per pixel (returned on exit)
C          RM - frequency marker spacing (returned on exit)
C          HT - maximum intensity
C       YSTEP - intensity step per pixel
C      INTADD - add/do not add intensities at a given pixel (-1 or +1)
C      LSTYLS - use/do not use declared linestyles (-1 or +1)
C      LCSCHE - use line colouring scheme based on transition type/set number
C               (-1 and +1 respectively)
C        ITXT - horizontal shift in number of characters for the annotation
C               lines to compensate for different numbers of columns in video
C               modes
C       BKCOL - the current background colour
C      nbordc - the current border colour
C      istico - plot control: sticks only (0), simulated contour (1), 
C               sticks+contour (2)
C
      USE DFLIB
C
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
C
      PARAMETER (MAXLIN=100000,maxspe=500)
      PARAMETER (ntextc=0, ntextb=7)
c
      REAL*4 S(MAXLIN),SMAX,ELOW(maxlin)
      REAL*8 F(MAXLIN),FMIN,FMAX,F1,F2,HT,FSTEP,YSTEP,YSHIFT,H,hh,ypix,
     * RM,FRMARK,FLONG,YY,HBOT,HTOP,fspa(maxspe),fspb(maxspe),
     * fa,fb,fc,fd
      INTEGER*4 LNUM(MAXLIN),N,bkcol
      INTEGER*2 LS,LSTYLE(10)
      INTEGER*4 DUMMY4
      INTEGER*1 SET(MAXLIN),LST(MAXLIN),NCOLOR(MAXLIN),LCOLOR(MAXLIN)
      INTEGER*2 INTADD,DUMMY2,LSTYLS,LCSCHE
      CHARACTER M(MAXLIN),BUFREQ*8
      INTEGER*2 maxx,maxy,mymode,myrows,mycols,linofs
      CHARACTER INFOIN(2)*8,INFOCO(2)*12,INFOLS(2)*10,spenam(maxspe)*12
      CHARACTER*79 toplin,botlin,emplin,seclin
      character*127 marlin
      COMMON /limits/wxy,maxx,maxy,LINOFS,curpos,ixy,
     * mymode,myrows,mycols
      COMMON /ORIGLN/SET,LST,NLSET,NCOLOR,LCOLOR
      COMMON /FRBLK/F/SBLK/FMIN,FMAX,ELOW,S,SMAX,NLINES
      COMMON /LNUMS/LNUM/DOUBL/M
      COMMON /LINES/toplin,botlin,emplin,seclin
      COMMON /SPECS/fspa,fspb,spenam,nsp
C
      DATA INFOIN/    'notADDED',    '   ADDED'/
      DATA INFOCO/'transCOLOURS','dtsetCOLOURS'/
      DATA INFOLS/  ' noLSTYLES',  'useLSTYLES'/
c
c...Linestyles:  
c
c   The SETLINESTYLE mechanism is no longer used since the change from PS1 to
c   WIN32 commands in PS4+ reduced available linestyles to only about four
c   different ones.  Instead linestyles are now generated within ASCP by using
c   the mechanism of gle by repeating pair or two pairs of on-off lengths 
c   declared by two digit or four digit numbers. 
C
C   1 = xxxxxxxx           2 = xxxxx_____        3 = xx__xx__
c   4 = xxxxxxxxx__xx__    5 = xx______          6 = xxxxxxxxx_________ 
c   7 = xxxxxx____xx____   8 = xxxxxxxx__        9 = xxxx__xxxx________
c  10 = xx__xx____
c
      DATA LSTYLE/80,  55,  22,9222,  26,  99,6424,  82,4248,2224/
c
      if(myrows.eq.30)then
        h=519.d0/500.d0
      else
        h=269.d0/250.d0
      endif
      ypix=ht*h/(real(maxy)-4.d0*(real(maxy)/myrows))
      WRITE(emplin,'(79(1H ))')
c
C...determine markers: RM=marker spacing, FRMARK=frequency of first marker
C
      FSTEP=F2-F1
      RM=100000.D0
1     NM=FSTEP/RM
      IF(NM.LT.15)THEN
        RM=RM*0.1D0
        GOTO 1
      ENDIF
      FRMARK=DINT(F1/RM)*RM
      IF(FRMARK.LT.F1)FRMARK=FRMARK+RM
C
C...scales
C
      do 100 n=1,mycols
        marlin(n:n)=' '
100   continue
      FSTEP=(F2-F1)/maxx
C
C...horizontal baseline
C
      DUMMY2=SETCOLOR(nbordc)
      YSHIFT=-5.d0*ystep
      CALL moveto_w(F1,YSHIFT,wxy)
      dummy2=lineto_w(F2,YSHIFT)
C
C
C...Plot the transition sticks
C
      if(istico.eq.1)goto 5
      DO 2 N=1,NLINES
        IF(F(N).GE.F1)GOTO 3
2     CONTINUE
      GOTO 5
C
3     IF(F(N).GT.F2.OR.N.GT.NLINES)GOTO 5
      H=S(LNUM(N))
      IF(INTADD.EQ.1)THEN
        IF(M(LNUM(N)).EQ.'D')H=H*2.0D0
        IF(getpixel_w(F(N),0.0D0).NE.bkcol)THEN
          HBOT=HTOP
          HTOP=HBOT+H
        ELSE
          HBOT=0.0D0
          HTOP=H
        ENDIF
      ELSE
        HBOT=0.0D0
        HTOP=H
      ENDIF
      IF(HTOP.GT.HT)HTOP=HT
      IF(HBOT.GT.HT)HBOT=HT
      IF(NLSET.GT.1)THEN
         if(lstyls.gt.0)LS=LSTYLE(LST(LNUM(N)))
      ENDIF
      DUMMY4=NCOLOR(LNUM(N))
      DUMMY2=SETCOLOR( DUMMY4 )
c
      if(ls.eq.80.or.lstyls.le.0)then
        CALL moveto_w(F(N),HBOT,wxy)
        dummy2=lineto_w(F(N),HTOP)
      else
        if(ls.lt.100)then
          nn=ls/10
          fb=ls-10*nn+1
          fa=nn
        else
          nn=ls/1000
          nnn=(ls-1000*nn)/100
          nnnn=ls/10
          nnnn=nnnn-10*(nnnn/10)
          nnnnn=ls-10*(ls/10)
          fa=nn
          fb=nnn+1
          fc=nnnn
          fd=nnnnn+1
        endif        
c
        h=hbot    
500     hh=h+fa*ypix
        if(hh.ge.htop)hh=htop
        CALL moveto_w(F(N),H,wxy)
        dummy2=lineto_w(F(N),HH)
        h=hh+fb*ypix
        if(h.ge.htop.or.hh.ge.htop)goto 501
        if(ls.lt.100)goto 500
c
        hh=h+fc*ypix
        if(hh.ge.htop)hh=htop
        CALL moveto_w(F(N),H,wxy)
        dummy2=lineto_w(F(N),HH)
        h=hh+fd*ypix
        if(h.ge.htop.or.hh.ge.htop)goto 501
        goto 500        
      endif
c
501   N=N+1
      GOTO 3
C
C...Frequency markers: 1/ draw graphics baseline and ticks
C                      2/ place labels in MARLIN
C
5     IF(NLSET.GT.1)CALL setlinestyle(#FFFF)
      FLONG=0.D0
C
4     YY=YSHIFT-5.D0*YSTEP
      H=DNINT(FRMARK/RM)
      IF(DNINT(10.D0*DINT(H*0.1D0)).EQ.H)THEN
        YY=YSHIFT-13.D0*YSTEP
        IF(FLONG.EQ.0.D0)FLONG=FRMARK
        NBUFER=(FRMARK-F1)/(F2-F1) * real(mycols)
        IF(NBUFER-3.GE.1.AND.NBUFER+4.LE.mycols-1)THEN
          WRITE(BUFREQ,'(F8.1)')FRMARK
          if(frmark.lt.100000.)WRITE(BUFREQ,'(F8.2)')FRMARK
          if(frmark.ge.1000000.)WRITE(BUFREQ,'(F8.0)')FRMARK
          IF(NBUFER-3.LE.4)THEN
            marlin(NBUFER-3:NBUFER+4)=BUFREQ
            GOTO 10
          ENDIF
          IF(marlin(NBUFER-6:NBUFER-6).EQ.' ')THEN
            marlin(NBUFER-3:NBUFER+4)=BUFREQ
          ENDIF
        ENDIF
      ENDIF
10    DUMMY2=SETCOLOR(nbordc)
      CALL moveto_w(FRMARK,YSHIFT,wxy)
      dummy2=lineto_w(FRMARK,YY)
      FRMARK=FRMARK+RM
      IF(FRMARK.LE.F2)GOTO 4
c
c...plot ranges of recorded spectra (if available)
c
      DUMMY2=SETCOLOR(12)
      if(nsp.gt.0)then
        do 200 n=1,nsp
          if(fspa(n).ge.f2)goto 201
          if(fspb(n).le.f1)goto 200
          fa=fspa(n)
          if(fa.lt.f1)fa=f1
          fb=fspb(n)
          if(fb.gt.f2)fb=f2
          YY=YSHIFT
          DO 202 NN=1,3
            YY=YY+YSTEP
            CALL moveto_w(Fa,YY,wxy)
            dummy2=lineto_w(Fb,YY)          
202       CONTINUE
          DUMMY2=SETCOLOR(4)
          CALL moveto_w(Fa,YSHIFT-ystep,wxy)
          dummy2=lineto_w(Fa,YSHIFT+4.0*YSTEP)          
          CALL moveto_w(Fb,YSHIFT-ystep,wxy)
          dummy2=lineto_w(Fb,YSHIFT+4.0*YSTEP)          
          DUMMY2=SETCOLOR(12)          
200     continue        
      endif
C
C...bottom line annotations
C
201   CALL settextposition(myrows,int2(itxt+29),curpos)
      dummy2=settextcolor( ntextc )
      dummy4 = setbkcolor( ntextb )
      CALL outtext('H = help')

      dummy4 = setbkcolor( 23 )
      CALL settextposition(myrows,int2(itxt+48),curpos)
      CALL outtext(INFOCO((LCSCHE+3)/2))
      CALL settextposition(myrows,int2(itxt+61),curpos)
      CALL outtext(INFOLS((LSTYLS+3)/2))
      CALL settextposition(myrows,int2(itxt+72),curpos)
      CALL outtext(INFOIN((INTADD+3)/2))
c
c...marker labels
c
      dummy4 = setbkcolor( ntextb )
      DUMMY2=SETTEXTCOLOR( 1)
      CALL settextposition(int2(myrows-1),int2(1),curpos)
      CALL outtext(marlin(1:mycols-1)//' ')
C
      RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE SORTH(NSTART,N)
c
c   This routine is based on the SORT2 'heapsort' routine from Numerical
c   Recipes and sorts the quantities in vector WK from WK(NSTART) to WK(N)
C   in ascending order of magnitude and also accordingly rearranges vector
C   IPT of pointers to original positions of sorted quantities.
c
      PARAMETER (MAXLIN=100000)
c
      COMMON /FRBLK/WK
      COMMON /LNUMS/IPT
      INTEGER*4 IPT(MAXLIN),IIPT,L,I,J,IR
      REAL*8 WK(MAXLIN),WWK
C
      L=N/2+1
      IR=N
10    CONTINUE
        IF(L.GT.NSTART)THEN
          L=L-1
          WWK=WK(L)
          IIPT=IPT(L)
        ELSE
          WWK=WK(IR)
          IIPT=IPT(IR)
          WK(IR)=WK(1)
          IPT(IR)=IPT(1)
          IR=IR-1
          IF(IR.EQ.NSTART)THEN
            WK(1)=WWK
            IPT(1)=IIPT
            RETURN
          ENDIF
        ENDIF
        I=L
        J=L+L
20      IF(J.LE.IR)THEN
          IF(J.LT.IR)THEN
            IF(WK(J).LT.WK(J+1))J=J+1
          ENDIF
          IF(WWK.LT.WK(J))THEN
            WK(I)=WK(J)
            IPT(I)=IPT(J)
            I=J
            J=J+J
          ELSE
            J=IR+1
          ENDIF
        GO TO 20
        ENDIF
        WK(I)=WWK
        IPT(I)=IIPT
      GO TO 10
c
      RETURN
      END
C
C_____________________________________________________________________________
C
      subroutine startg(iconf)
c
C   This routine uses QWIN graphics and techniques from the CLEANWIN programming
C   example for CVF6 to avoid the full-screen startup of standard graphics,
C   while preserving a simple frame.  
C   Note the use of the WIN32 routines MoveWindow, UpdateWindow, GetWindowLong,
C   SetWindowLong, GetHWndQQ - their operation and parameter values are not
C   really understood!
c
      USE DFLIB
      USE DFWIN
c
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
      INTEGER*2 maxx,maxy,linofs,mymode,myrows,mycols,ifc,ifm,ifhb,ifb,
     *          idelta
      integer*4 dummy4,i
      character fntnam*30,line*80
      COMMON /limits/wxy,maxx,maxy,linofs,curpos,ixy,
     * mymode,myrows,mycols
      COMMON /gsets/wc,win,ifc,ifm,ifhb,ifb,idelta
      type (windowconfig)wc
      type (qwinfo)win
      logical status
C
C...Determine the type of Windows (using a WIN32 function) 
c      
c     type (t_OSVERSIONINFO)os    
c     os.dwOSVersionInfoSize=sizeof(os)
c     status=GetVersionEx( os )
c     ntsys=os.dwPlatformId-1
C
C...An alternative way to determine the type of Windows, but this has the 
C   the disadvantage of a flashing COMMAND PROMPT screen
C
c     status=SYSTEMQQ('ver>opsys.ver')
c     open(3,file='opsys.ver',status='unknown')
c     read(3,'(A)')line
c     read(3,'(A)')line
c     if(line(1:7).eq.'Windows')then
c       ntsys=0
c     else
c       ntsys=1
c       if(line(1:20).eq.'Microsoft Windows XP')ntsys=2
c     endif
c     close(3)
c     status=SYSTEMQQ('del opsys.ver')
c
c...set the principal window parameters, as hardcoded below and
c   specified in the ASCP.CFG file
c
      wc.numtextcols=80
      wc.numtextrows=30
c
      open(3,file='c:\rot\ascp.cfg',status='old',err=12)
7       read(3,'(a)')line
        if(line(1:1).eq.'!')goto 7
        read(line,5)wc.numxpixels
        read(3,'(a)')line
        read(line,5)wc.numypixels
        read(3,'(a)')line
        fntnam=line(36:65)
5       format(35x,i4)
c
        wc.fontsize=QWIN$EXTENDFONT
        wc.numcolors=-1
        wc.extendfontname=trim(fntnam)//char(0)
        wc.extendfontsize=-1
c
        wc.extendfontattributes=0
8       read(3,'(a)')line
        if(line(1:1).eq.'!')goto 9
        read(line,5)iattr
        if(iattr.lt.1.or.iattr.gt.15)then
           write(*,10)iattr
10         format(1x//' Extended font attribute from ASCP.CFG is',i5,
     *                ', which is illegal (1-15 allowed)'//
     *                ' **** TRY AGAIN! *****'//)
           pause
           stop
        endif
      if(iattr.eq. 1)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_NORMAL
      if(iattr.eq. 2)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_UNDERLINE
      if(iattr.eq. 3)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_BOLD
      if(iattr.eq. 4)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_ITALIC
c
      if(iattr.eq. 5)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_FIXED_PITCH
      if(iattr.eq. 6)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_VARIABLE_PITCH
c
      if(iattr.eq. 7)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_FF_ROMAN
      if(iattr.eq. 8)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_FF_SWISS
      if(iattr.eq. 9)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_FF_MODERN
      if(iattr.eq.10)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_FF_SCRIPT
      if(iattr.eq.11)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_FF_DECORATIVE
c
      if(iattr.eq.12)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_ANSI_CHARSET
      if(iattr.eq.13)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_DEFAULT_CHARSET
      if(iattr.eq.14)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_SYMBOL_CHARSET
      if(iattr.eq.15)wc.extendfontattributes=wc.extendfontattributes
     *               +QWIN$EXTENDFONT_OEM_CHARSET
      goto 8
c
9     close(3)
      iconf=1
      goto 11
C
C...open default sized window for a 800x600 screen if the configuration file
C   cannot be opened
C
12    wc.numxpixels=800
      wc.numypixels=540
      wc.extendfontname='Courier New'
      iconf=0
C
C...Kill menu
C
11    DO I = 7,1,-1
	 STATUS= DELETEMENUQQ(I, 0)
      END DO
C
C...Kill status bar
C
      i = clickqq( QWIN$STATUS )
C
C...Kill scroll bars and unwanted features (note that the title seems possible
C   only on the (killed) daughter window and not on the framewindow
C
      i = GetWindowLong( GetHWndQQ(QWIN$FRAMEWINDOW), GWL_STYLE )
      i = ior( iand( i, not(WS_THICKFRAME) ), WS_BORDER )
      i = iand( i, not(WS_MAXIMIZEBOX) )
      k = SetWindowLong( GetHWndQQ(QWIN$FRAMEWINDOW), GWL_STYLE, i )    
C
      i = GetWindowLong( GetHWndQQ(0), GWL_STYLE )
      i = ior(iand( i, not(WS_CAPTION.or.WS_SYSMENU.or.WS_THICKFRAME)), &
     &    WS_BORDER)
      k = SetWindowLong( GetHWndQQ(0), GWL_STYLE, i )     
c
c...Position window - for compatibility with small pixel size screens make the
c   top and left edge of the bounding frame disappear
c   
      ifxed= GetSystemMetrics(sm_cxfixedframe)
      ifyed= GetSystemMetrics(sm_cyfixedframe)
      win.x = -ifxed
      win.y = -ifyed
c
c...Correct sizing parameters to take account of removal of the menu bar and of 
c   the caption area for the child window - these vary with system font size and
c   are augmented with emprirically established IDELTA fudge parameter
C   
C
C  W98,ME small fonts:        ifc=19 ifm=19 idelta=5 -> sum=43
C  W2000, small=100% fonts:   ifc=19 ifm=19 idelta=5 -> sum=43
C  W2000, large=125% fonts:   ifc=24 ifm=24 idelta=4 -> sum=52
C  W2000, custom=132% fonts:  ifc=25 ifm=25 idelta=3 -> sum=53
C  WindowsXP,small fonts:     ifc=26 ifm=20 idelta=2 -> sum=48
C 
C
      ifc  = GetSystemMetrics(sm_cycaption)
      ifm  = GetSystemMetrics(sm_cymenu)
      ifhb = GetSystemMetrics(sm_cxborder)
      ifb  = GetSystemMetrics(sm_cyborder)
c     write(*,*)ifc,ifm,ifb,ifhb,ifxed,ifyed
c     pause
c      
      idelta=4
      if(ifc.eq.19.and.ifc.eq.19)idelta=5                                             
      if(ifc.eq.25.and.ifc.eq.25)idelta=3                                             
      if(ifc.ge.26)idelta=2                                             
c           
      win.w = wc.numxpixels-2*ifhb
      win.h = wc.numypixels-(ifc+ifm+idelta)

      win.type=qwin$set
      dummy4 = setwsizeqq(qwin$framewindow,win)
      status = getwsizeqq(QWIN$FRAMEWINDOW,QWIN$SIZECURR, win)
c
      wc.numtextcols=80
      wc.numtextrows=30
      wc.title=' 'C
c 
      status=setwindowconfig(wc)
      if(.not.status)status=setwindowconfig(wc)
C
C...Magical Windows incantations to make style set above real (without
C   these commands the active window does not expand to the size of the 
C   program framewindow)
C     
      i = MoveWindow( GetHWndQQ(0), -1, -1, 0, 0, .TRUE.) 
      call clearscreen($GCLEARSCREEN)
      status = UpdateWindow(GETHANDLEFRAMEQQ())    
c
C  pixel limits on x and y axes (0,maxx), (0,maxy)
c
      maxx=wc.numxpixels-1
      maxy=wc.numypixels-1
      myrows=wc.numtextrows
      mycols=wc.numtextcols
      linofs=nint(real(maxy)/real(myrows))+1
c
      return
      end
C
C_____________________________________________________________________________
c
      subroutine nargr
c
c   This routine toggles between 30 and 17 row text window corresponding to 
c   normal height and half-height of the graphics
c
      USE DFLIB
      USE DFWIN
c
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
      INTEGER*2 maxx,maxy,linofs,mymode,myrows,mycols,ifc,ifm,ifhb,ifb,
     *          idelta
      COMMON /limits/wxy,maxx,maxy,linofs,curpos,ixy,
     * mymode,myrows,mycols
      COMMON /gsets/wc,win,ifc,ifm,ifhb,ifb,idelta
      type (windowconfig)wc
      type (qwinfo)win
      logical status
c
      wc.numtextcols=80
      if(myrows.eq.30)then
        wc.numtextrows=17
        wc.numypixels=((maxy+1)/30)*17
      else
        wc.numtextrows=30
        wc.numypixels=((maxy+1)/17)*30
      endif      
c
      wc.numxpixels=maxx+1
c
      status = getwsizeqq(QWIN$FRAMEWINDOW,QWIN$SIZECURR, win)
C    
      win.w = wc.numxpixels-2*ifhb
      win.h = wc.numypixels-(ifc+ifm+idelta)

      win.type=qwin$set
      dummy4 = setwsizeqq(qwin$framewindow,win)
      status = getwsizeqq(QWIN$FRAMEWINDOW,QWIN$SIZECURR, win)
C
C...set window parameters
C
      status=setwindowconfig(wc)
      if(.not.status)status=setwindowconfig(wc)
C
C...Magical Windows incantations to make style set above real (without
C   these commands the active window does not expand to the size of the 
C   program framewindow)
C
      i = MoveWindow( GetHWndQQ(0), -1, -1, 0, 0, .TRUE.) 
      call clearscreen($GCLEARSCREEN)
      status = UpdateWindow(GETHANDLEFRAMEQQ())        
c
C  pixel limits on x and y axes (0,maxx), (0,maxy)
c
      maxx=wc.numxpixels-1
      maxy=wc.numypixels-1
      myrows=wc.numtextrows
      mycols=wc.numtextcols
      linofs=nint(real(maxy)/real(myrows))+1
c
      return
      end
C
C_____________________________________________________________________________
C
      SUBROUTINE HUNTF(N,X,JLO)
C
C   This is a modification of routine HUNT from Numerical Recipes for
C   locating a value in an ordered table.  The required value is located
C   by hunting from the latest known position in the table.
c
C   Given an array XX of length N, and given a value X, the routine returns
C   a value JLO such that X is between XX(JLO) and XX(JLO+1).  XX must be
C   monotonic, either increasing or decreasing.  JLO=0 or JLO=N is
C   returned to indicate that X is out of range.  JLO on input is taken as
C   the initial guess for JLO on output.
C
      PARAMETER (MAXLIN=100000)
c
      real*8 x,xx(MAXLIN)
      integer*4 n,jlo,jhi,inc,jm
      LOGICAL ASCND
      COMMON /FRBLK/xx
C
      ASCND=XX(N).GT.XX(1)
      IF(JLO.LE.0.OR.JLO.GT.N)THEN
        JLO=0
        JHI=N+1
        GO TO 3
      ENDIF
c
      INC=1
      IF(X.GE.XX(JLO).EQV.ASCND)THEN
1       JHI=JLO+INC
        IF(JHI.GT.N)THEN
          JHI=N+1
        ELSE IF(X.GE.XX(JHI).EQV.ASCND)THEN
          JLO=JHI
          INC=INC+INC
          GO TO 1
        ENDIF
      ELSE
        JHI=JLO
2       JLO=JHI-INC
        IF(JLO.LT.1)THEN
          JLO=0
        ELSE IF(X.LT.XX(JLO).EQV.ASCND)THEN
          JHI=JLO
          INC=INC+INC
          GO TO 2
        ENDIF
      ENDIF
c
3     IF(JHI-JLO.EQ.1)RETURN
      JM=(JHI+JLO)/2
      IF(X.GT.XX(JM).EQV.ASCND)THEN
        JLO=JM
      ELSE
        JHI=JM
      ENDIF
      GO TO 3
c
      RETURN
      END
C_____________________________________________________________________________
c
      integer*2 function INKEY(N2)
c
c   By L Pszczolkowski:
c
c...This emulates    for MSF PS1.0 the INKEY function of Z.Czumaj which
c   in turn emulated for MSF5.0    the INKEY function from IIUWGRAF graphics
c   library for the Hercules card
c
c   The function GETCHARQQ returns the ASCII character if the corresponding
c   key was pressed.  If function or direction key was pressed then 0
c   or hex E0 is returned and another call to GETCHARQQ is required to
c   get the extended code of the character
c
      USE DFLIB
c
      INTEGER*2 IK,n2
      CHARACTER*1 KK
c
      KK=GETCHARQQ()
      IK=ICHAR(KK)
      IF(IK.EQ.0 .OR. IK.EQ.224 ) THEN
          KK=GETCHARQQ()
          IK=-ICHAR(KK)
      ENDIF
      n2=ik
      INKEY=IK
      END
C_____________________________________________________________________________
C_____________________________________________________________________________


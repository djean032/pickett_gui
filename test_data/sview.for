C_____________________________________________________________________________
C
C   SVIEW  -  DISPLAY AND MEASUREMENT PROGRAM FOR LINEARIZED SPECTRA
C_____________________________________________________________________________
C
C
C   Version 26.VIII.2004                          ----- Zbigniew Kisiel -----
C
C                          __________________________________________________
C                         | Institute of Physics, Polish Academy of Sciences |
C                         | Al.Lotnikow 32/46, Warszawa, POLAND              |
C                         |                             kisiel@ifpan.edu.pl  |
C                         |     http://info.ifpan.edu.pl/~kisiel/prospe.htm  |
C_________________________/--------------------------------------------------
C
C  Modification history:
C
C  31.3.95:  Elimination of crash on option XL for narrow spectra and of
C            crash on evaluation of peak frequency for level signal
C   6.6.95:  Change of peakfinder width with 0 not O
C  31.8.95:  Addition of safety features on input and .FRE compatibility
C 26.11.95:  Tweaking of screen refresh in LOOK
C 11.02.97:  As above
C  9.06.97:  Test for frequencies increasing from left to right
C 27.03.01:  gle output
C 24.04.01:  major reconstruction
C  7.05.01:  more checks of ASCII input + debugging
C 15.12.01:  improved subtraction and restore options + config. file
C  5.03.02:  more CVF6 compliance, improved baseline subtr. and ASCII input
C  3.01.03:  switch to QWIN graphics and an optional half-height screen 
C 24.03.03:  display of spectral information
C 30.07.03:  modifications for use with very long spectra
C 14.08.03:  sorting out Window frame-size compatibility problems
C 16.02.04:  campatibility of AUTOPK with long spectra
C 25.05.04:  append option for spectra
C 26.08.04:  enhanced peak measurement + incremental modifications
C
C
C-----------------------------------------------------------------------------
C     I N S T A L L A T I O N:
C-----------------------------------------------------------------------------
C
C     1/ place SVIEW.EXE and SVIEW.CFG in directory C:\ROT
C     2/ using Windows Explorer send a shortcut to SVIEW to the desktop
C     3/ add C:\ROT to the PATH if it is planned to launch from the command
C        prompt
C
C
C-----------------------------------------------------------------------------
C     S V I E W   A N D   W I N D O W S:
C-----------------------------------------------------------------------------
C
C     In Win95/98 it is best to launch SVIEW from the command line, after
C     having moved to the directory which contains the required files.
C     The current directory is assumed to be the default directory.
C
C     In Win2000, irrespective of launch type, the system remembers the last
C     directory in which SVIEW was used and assumes it as default.  If this
C     directory is no longer to be worked on then it is necessary to
C     navigate to the required directory using the FileSelect window.
C
C     Drag and drop operation is possible.  The spectral file can be dragged
C     onto the SVIEW icon and, once file type option is set as necessary,
C     the dragged file will be read in and processed as required.
C
C     All output files (processed spectrum, peakfinder, gle) are written to
C     the directory from which the data file was read.
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
C    previously
C
C
C-------------------------------- 
C    Command line compilation:
C-------------------------------- 
C
C    Simplest compilation for the local machine:
C
C        df -static -libs=qwin -fpscomp:filesfromcmd sview.for
C
C    Optimised compilation for any PENTIUM:
C
C        df -check:all -nodebug -traceback -arch=pn1 -tune=pn1
C           -fast -static -libs=qwin -fpscomp:filesfromcmd sview.for
C
C    Other processor options are pn2,pn3,pn4,k6_2,k7
C
C-------------------------------- 
C    Visual Studio compilation:
C-------------------------------- 
C
C    FORTRAN:  /check:all /compile_only /fpscomp:filesfromcmd
C              /libs:qwin /nologo /nopdbfile /optimize:3 /traceback /tune:pn1 
C              /architecture:pn1 /static
C
C    LINK:     kernel32.lib /nologo /subsystem:windows /pdb:none 
C              /machine:IX86 /out:"Debug/pmifst.exe"
C
C    In addition the compilation option /check:all may be used to catch out
C    suspicious run-time conditions, but it is only recommended for debugging
C
C
C===========================================================================
C
C...Initialization commands for graphics.  The three structured
C   variables contain coordinates:
C     curpos.row and curpos.col - cursor coordinates (INTEGER*2)
C     ixy.xcoord and ixy.ycoord - pixel coordinates (INTEGER*2)
C     wxy.wx and wxy.wy - window coordinates (REAL*8)
C
C
      USE DFLIB
C_____________________________________________________________________________
C
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (ntextc=0, ntextb=7, ncomc=15, ncomb=1)
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
C
      REAL*8 FREQs(MAXPTS)
      INTEGER*2 maxx,maxy,linofs,mymode,myrows,mycols,iflag
      INTEGER*2 fontnum, numfonts
      REAL*8 FSTART,FEND,FINCR,freq
      REAL*4 volts(MAXPTS)
      CHARACTER errmes*40,gener*60
      CHARACTER*80 toplin,emplin,paslin,botlin
c
      INTEGER*4 ISPEC(MAXPTS),NPTS,ISMALL,ILARGE,dummy4
      INTEGER*4 IOSPEC(maxpts),itemp(maxpts),icutof(maxpts)
      INTEGER*2 ita,itb,itc
      INTEGER*2 IDAY,IMON,IYEAR,IHOUR,IMIN,ISEC,dummy
      REAL*4 VKMST,VKMEND,GRID,SAMPRE,GAIN,TIMEC,PHASE,
     1 PPS,FRMOD,FRAMPL
      CHARACTER FILNAM*50,COMENT*72,LAMP*6,SCANSP*6,SAMPLE*20
c
      COMMON /SPECR/volts
      COMMON /SPEC/ISPEC,NPTS,ISMALL,ILARGE
      common /bufers/iospec,itemp,icutof
      COMMON /FRE/FREQS
      COMMON /limits/wxy,maxx,maxy,linofs,curpos,ixy,
     * mymode,myrows,mycols
      COMMON /INFOC/COMENT,SAMPLE,LAMP,SCANSP
      COMMON /INFO/IDAY,IMON,IYEAR,IHOUR,IMIN,ISEC,
     1 VKMST,VKMEND,GRID,SAMPRE,GAIN,TIMEC,PHASE,
     1 PPS,FRMOD,FRAMPL
      COMMON /lines/toplin,emplin,paslin,botlin
      COMMON /FNAM/FILNAM
      COMMON /FLIMIT/FSTART,FEND,FINCR
C
C
C...start graphics
C
      call startg(iconf)
      dummy4=passdirkeysqq(.true.)
C
C
C...HEADER
C
      numfonts = INITIALIZEFONTS ( )
      fontnum = SETFONT ('t''Arial''h75w25ei')
      dummy4=setbkcolor(ntextb)
      call clearscreen($gclearscreen)
c
      NBOTL=110
      dummy=setcolor(15)
      CALL MOVETO (INT2( 0), INT2(NBOTL), ixy)
      dummy=lineto(INT2( maxx), INT2(NBOTL))
      CALL MOVETO (INT2( 0), INT2(0), ixy)
      dummy=lineto(INT2( maxx), INT2(0))
      dummy=setcolor(8)
      dummy=floodfill(1,1,15)
c
      nvert=(NBOTL-75)/2
      nhor=(maxx-620)/2
      dummy=setcolor(11)
      CALL MOVETO (INT2(nhor), INT2(nvert), ixy)
      CALL OUTGTEXT('SVIEW - Spectral VIEWer')
      dummy=setcolor(9)
      CALL MOVETO (INT2(nhor+1), INT2(nvert+1), ixy)
      CALL OUTGTEXT('SVIEW - Spectral VIEWer')
      dummy=setcolor(1)
      CALL MOVETO (INT2(nhor+2), INT2(nvert+2), ixy)
      CALL OUTGTEXT('SVIEW - Spectral VIEWer')
c
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
      CALL OUTGTEXT('version 26.VIII.2004')
      CALL MOVETO (INT2( maxx-169), INT2(NBOTL+ 7), ixy)
      CALL OUTGTEXT('Zbigniew KISIEL')
      dummy=setcolor(15)
      CALL MOVETO (INT2( 10), INT2(NBOTL+ 6), ixy)
      CALL OUTGTEXT('version 26.VIII.2004')
      CALL MOVETO (INT2( maxx-170), INT2(NBOTL+ 6), ixy)
      CALL OUTGTEXT('Zbigniew KISIEL')
c
      nrlin=nint(real(NBOTL+32)/(real(maxy)/real(myrows)))+2
      call settextposition(nrlin,65,curpos)
      dummy=settextcolor(ntextc)
      write(*,'(i8,'' points'',$)')maxpts
c
      call sgame
c
C...Warn of missing config file
C
70    call settextposition(10,1,curpos)
      if(iconf.eq.0)then
        dummy=setcolor(12)
        fontnum = SETFONT ('t''Arial''h18w9e')
        CALL MOVETO (INT2(100), INT2(200), ixy)
        CALL OUTGTEXT(
     *    'Configuration file C:\ROT\SVIEW.CFG was not found:')
        CALL MOVETO (INT2(250), INT2(220), ixy)
        fontnum = SETFONT ('t''Arial''h18w9i')
        CALL OUTGTEXT(
     *    'default sized window of 800x540 pixels will be used')
        call settextposition(15,1,curpos)
      endif
c
C
C...Input of a stored spectrum
C
      WRITE(emplin,'(80(1H ))')
1     format(i5)
      dummy=settextcolor(ntextc)
      dummy4=setbkcolor(ntextb)
c
      filnam=''
      gener=''
1503  WRITE(*,1519)
1519  FORMAT(1x/10x,'TYPE ONE OF:'//
     * 14x,'Name of data file,'/
     * 14x,'Generic name for use in the SelectFile box,'/
     * 14x,'ENTER for the default or previous SelectFile box'/)
      dummy=displaycursor($gcursoron)
      WRITE(*,'(10X,''... '',$)')
      READ(*,'(A)',ERR=1515)FILNAM
c
c...standard SelectFile box
c
      CALL SETMESSAGEQQ(
     * " All Files (*.*), *.*;"//
     * " Spectral Files (*.0*), *.0*; Spectral Files (*.1*), *.1*;"//
     * " Spectral Files (*.2*), *.2*;"//
     * " Spectral Files (*.3*), *.3*;",
     *                  QWIN$MSG_FILEOPENDLG)
      if(filnam.ne.'')goto 1504
      if(filnam.eq.''.and.gener.eq.'')goto 1504
c
c...SelectFile box with generic entry as first option
c
      if(gener.ne.'')goto 1520
1515  if(filnam.ne.'')then
        do 1518 n=1,len_trim(filnam)+1
          if(filnam(n:n).eq.':'.or.filnam(1:1).eq.' ')then
            gener=''
            goto 1516
          endif
          if(filnam(n:n).eq.'.'.or.filnam(n:n).eq.'\')goto 1517
          if(filnam(n:n).eq.' '.or.filnam(:n).eq.char(0))goto 1517
1518    continue
        gener=''
        goto 1516
1517    n=n-1
        if(n.ge.1)then
          gener=' '//filnam(1:n)//' files ('//filnam(1:n)//'*.*), '//
     *               filnam(1:n)//'*.*;'
        else
          gener=''
        endif
      else
        gener=''
      endif
1516  filnam=''
c
1520  n=len_trim(gener)
      if(n.le.0)then
      else
         CALL SETMESSAGEQQ( gener(1:n)//
     * " All Files (*.*), *.*;"//
     * " Spectral Files (*.0*), *.0*; Spectral Files (*.1*), *.1*;"//
     * " Spectral Files (*.2*), *.2*;"//
     * " Spectral Files (*.3*), *.3*;",
     *                  QWIN$MSG_FILEOPENDLG)
      endif
c
c...open the file
c
1504  OPEN(2,FILE=FILNAM,FORM='BINARY',STATUS='OLD',ERR=1515)
      IF(filnam.eq.'')inquire(2,name=filnam)
c
c_______________________________________________________
c
c...standard binary format
c
      READ(2,ERR=503,END=503)COMENT,IDAY,IMON,IYEAR,IHOUR,IMIN,ISEC,
     1 LAMP,VKMST,VKMEND,GRID,SAMPLE,SAMPRE,GAIN,TIMEC,PHASE,
     1 SCANSP,PPS,FRMOD,FRAMPL
      READ(2)ita
      if(ita.gt.1)then
        NPTS=ita
        READ(2)itb,itc
        ISMALL=itb
        ILARGE=itc
      else
        READ(2)NPTS
      endif
      if(iday.lt.1.or.iday.gt.31)goto 503
      if(imon.lt.1.or.imon.gt.12)goto 503
      if(iyear.lt.1980.or.iyear.gt.2050)goto 503
c
      do 800 n=1,72
        if(ichar(coment(n:n)).lt.32.or.ichar(coment(n:n)).gt.127)
     *    coment(n:n)='#'
800   continue
      do 801 n=1,20
        if(ichar(sample(n:n)).lt.32.or.ichar(sample(n:n)).gt.127)
     *    sample(n:n)='#'
801   continue
      do 802 n=1,6
        if(ichar(lamp(n:n)).lt.32.or.ichar(lamp(n:n)).gt.127)
     *    lamp(n:n)='#'
        if(ichar(scansp(n:n)).lt.32.or.ichar(scansp(n:n)).gt.127)
     *    scansp(n:n)='#'
802   continue
C
      dummy4= setbkcolor(ntextb)
      call clearscreen($GCLEARSCREEN)
      fstart=0.d0
      fend=0.d0
      call speinf(myrows)
C
      if(npts.gt.maxpts)then
        write(*,'(1x//1x,i5,'' points in spectrum which exceeds'',
     * '' present maximum of '',i5//)')npts,maxpts
        stop
      endif
      ISMALL= 1000000000
      ILARGE=-1000000000
      DO 20 N=1,NPTS
        READ(2,ERR=494)ita
        ISPEC(N)=ita
        if(ispec(n).lt.ismall)ismall=ispec(n)
        if(ispec(n).gt.ilarge)ilarge=ispec(n)       
20    CONTINUE
c
      goto 495
494     write(*,'(1x//''  PROBLEMS WITH INPUT OF INTENSITIES at pt. '',
     *   i5//)')n
        stop
495   continue
C
      READ(2,err=700,end=700)FSTART,FEND,FINCR
      WRITE(*,'(15x,''frequency from'',F11.2,''  to'',F10.2,
     1 '', step size'',F8.5/)')FSTART,FEND,FINCR
      IF(FEND.LE.FSTART.or.fincr.lt.0.d0)goto 700
      goto 1000
c
700   call clearscreen($gclearscreen)
      call sgame
      call settextcolor(12)
      WRITE(*,'(1x/10x,''PROBLEMS WITH FREQUENCY LIMITS:''//14x,
     * ''This may be a file in one of the old data standards,'',
     * /14x,''in which case try using MODSPE''//)')
      call settextcolor(ntextc)
      goto 1503
c
c_______________________________________________________
C
C...Input from an ASCII file which is executed once binary read fails
C   (data is treated as linearized file and only the frequency values
C    of the first and last points matter)
C
503   call clearscreen($gclearscreen)
      WRITE(*,492)
492   FORMAT(1X/'---- This is not a file in the IFPAN binary format:',
     * ' will now try reading it'/
     *          '     as two column ASCII, assuming that first line '
     * 'contains'/
     *          '     a descriptive comment'///)
      CLOSE(2)
      OPEN(2,FILE=FILNAM,ERR=489)
      errmes='Problem with the comment'
      READ(2,1300,ERR=489,END=489)COMENT
1300  FORMAT(A)
c
c...first pass to determine scaling
c
      NPTS=maxpts
      ASCMIN= 1.E20
      ASCMAX=-1.E20
      errmes='Problem with the X,Y pairs'
      DO 488 N=1,NPTS
490     READ(2,*,ERR=490,end=1505)XASC,YASC
        IF(YASC.GT.ASCMAX)ASCMAX=YASC
        IF(YASC.LT.ASCMIN)ASCMIN=YASC
488   CONTINUE
      goto 1506
C
C...second pass to fill the data tables
C
1505  NPTS=n-1
      if(ascmax.eq.ascmin)then
        errmes='Zero range of Y-values'
        goto 489
      endif
      if(npts.le.3)then
        errmes='Too few X,Y pairs'
        goto 489
      endif
c
1506  REWIND(2)
      READ(2,1300)CHARFL
      SCASC=20000.D0/(ASCMAX-ASCMIN)
      incfre=1
      DO 487 N=1,NPTS
491     READ(2,*,err=491)freqs(n),YASC
        ISPEC(N)=(YASC-ASCMIN)*SCASC-10000.D0
        if(n.gt.1)then
          if(freqs(n).lt.freqs(n-1))incfre=-1
        endif
487   CONTINUE
      if(incfre.eq.-1)then
        errmes='Frequencies not continuously increasing'
        goto 489
      endif
      fstart=freqs(1)
      fend=freqs(npts)
      fincr=(fend-fstart)/(npts-1)
      if(fstart.eq.fend)then
        errmes='Zero frequency range'
        goto 489
      endif
c
      ISMALL=-10000
      ILARGE=10000
      PPS=51.
      IDAY=1
      IMON=1
      IYEAR=2000
      WRITE(SAMPLE,'(1P(2E10.3))')ASCMIN,ASCMAX
      SCANSP=' '
      LAMP=' '
c
      call clearscreen($GCLEARSCREEN)
      write(*,'(''  Successful ASCII input from: '',$)')
      DUMMY=SETTEXTCOLOR(12)
      write(*,'(a)')filnam(1:len_trim(filnam))
      DUMMY=SETTEXTCOLOR(ncomc)
      dummy4= setbkcolor(ncomb)
      call settextposition(3,3,curpos)
      call outtext(emplin(1:76))
      WRITE(toplin,502)COMENT
502   format(2x,A72,2(1H ))
      call settextposition(4,3,curpos)
      call outtext(toplin(1:76))
      call settextposition(5,3,curpos)
      call outtext(emplin(1:76))
      DUMMY=SETTEXTCOLOR(ntextc)
      dummy4= setbkcolor(ntextb)
      WRITE(*,'(1X//1X,I7,'' points:  intensity from''
     1 ,1PE12.4,'' to'',E12.4)')NPTS,ASCMIN,ASCMAX
       WRITE(*,'(''                  frequency from  '',F10.2,
     * '' to  '',F10.2,
     1  ''      ''/)')FSTART,FEND
c
c...check of equidistance between points
c
      errmax=0.
      sumerr=0.
      delmin=1.E+20
      delmax=-1.E+20
      do 655 n=2,npts
        freq=fstart+(n-1)*fincr
        err=abs(freq-freqs(n))
        if(err.gt.errmax)then
          errmax=err
          nerrmx=n
        endif
        deltaf=freqs(n)-freqs(n-1)
        if(deltaf.lt.delmin)then
          delmin=deltaf
          ndmin=n
        endif
        if(deltaf.gt.delmax)then
          delmax=deltaf
          ndmax=n
        endif
        sumerr=sumerr+err
655   continue
c
      if(errmax.gt.fincr*0.1d0)then
        call settextcolor(12)
        write(*,657)
657     format(1x/10x,'The data is not linear in frequency:'/)
        call settextcolor(ntextc)
        write(*,656)errmax,nerrmx,freqs(nerrmx),
     *    delmax,ndmax,freqs(ndmax),
     *    delmin,ndmin,freqs(ndmin), fincr,
     *    sumerr,sumerr/(npts-1)
656     format(
     *   10x,' Maximum deviation = ',f12.5,'  at point',i7,f15.5/
     *   10x,'      Maximum step = ',F12.5,'  at point',i7,f15.5/
     *   10x,'      Minimum step = ',F12.5,'  at point',i7,f15.5/
     *   10x,'      DeltaF/(n-1) = ',f12.5//
     *   10x,' Sum of deviations = ',f12.5/
     *   10x,' average deviation = ',f12.5//)
c
        write(*,658)
658     format(10x,'SVIEW will now linearise the frequency axis by ',
     *  'linear interpolation,'/
     *         10x,'but you might still want to check the input'//)
c
        nsp=1
        do 659 n=2,npts-1
          freq=fstart+(n-1)*fincr
662       if(freqs(nsp+1).le.freq)then
            nsp=nsp+1
            goto 662
          endif
          iospec(n)=ispec(nsp)+(ispec(nsp+1)-ispec(nsp))*
     *              (freq-freqs(nsp))/(freqs(nsp+1)-freqs(nsp))
659     continue
c
        do 661 n=2,npts-1
          freq=fstart+(n-1)*fincr
          freqs(n)=freq
          ispec(n)=iospec(n)
661     continue
c
      endif
c
       goto 4565
c
489    call clearscreen($gclearscreen)
       write(*,'(1x/10x,''File:  '',$)')
       call settextcolor(12)
       write(*,'(a)')filnam(1:len_trim(filnam))
       call settextcolor(ntextc)
       write(*,'(1x/10x,''Unsuccessful ASCII input:  '',$)')
       write(*,'(a)')errmes(1:len_trim(errmes))
       if(n.gt.0)
     *    write(*,'(10x,''         Failed at point:  '',i6//)')n
       call sgame
       goto 1503
c
c_______________________________________________________
C
C
C...fill out the frequency table
c
1000  DO 4566 N=1,NPTS
        FREQS(N)=FSTART+(N-1)*FINCR
4566  CONTINUE
c
4565  CLOSE(2)
C
C
C...Scaling and plot
C
500   IF(ISMALL.EQ.ILARGE)THEN
        WRITE(*,'(1X/'' ****ERROR, zero dynamic range in data''/)')
        GOTO 1410
      ENDIF
c
      dummy=displaycursor($gcursoroff)
      WRITE(*,'(/''  Ready to plot - press ENTER  ''\)')
900   ik=inkey(int2(n))
      if(ik.ne.13)goto 900
c
505   CALL LOOKFM
      dummy=settextcolor(ntextc)
      dummy4= setbkcolor(ntextb)
      dummy=displaycursor($gcursoron)
506   call clearscreen($GCLEARSCREEN)
      dummy=setcolor(1)
      call sgame
      call settextposition(1,1,curpos)
C
1410  WRITE(*,'(1X/
     *   9X,''-1 = EXIT''/
     *  10X, ''0 = another spectrum''/
     *  10X, ''1 = another look at the spectrum from  '',$)')
      dummy=settextcolor(12)
      if(len_trim(filnam).le.25)then
        WRITE(*,'(a)')filnam(1:25)
      else
        nc=len_trim(filnam)
        write(*,'(a)')'...'//filnam(nc-24:nc)
      endif
      dummy=settextcolor(ntextc)
      write(*,'(1x/10x,''... '',$)')
      READ(*,1,ERR=506)IFLAG
      IF(IFLAG.EQ.0)GOTO 1503
      IF(IFLAG.EQ.1)GOTO 505
      IF(IFLAG.ne.-1)goto 506
C
530   dummy=setexitqq(qwin$exitnopersist)
c
      stop
      end
C
C_____________________________________________________________________________
c
      subroutine startg(iconf)
C
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
      logical*4 status
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
c   specified in the SVIEW.CFG file
c
      wc.numtextcols=80
      wc.numtextrows=30
c
      open(3,file='c:\rot\sview.cfg',status='old',err=12)
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
10         format(1x//' Extended font attribute from SVIEW.CFG is',i5,
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
c
c...open default sized window for a 800x600 screen if the configuration file
c   cannot be opened
c
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
c
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
      INTEGER*4 dummy4
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
      SUBROUTINE LOOKFM
C
C   Plot of spectrum with scrolling along the X-axis and zooming along
C   both the X and Y axes
C
C   Plot is normally made from FREQS,ISPEC but when points become too far
C   apart they are interpolated as necessary at each screen refresh
C   (since time delay is minimal)
C
C   - ISPEC() contains the current spectrum
C   - ITEMP() work buffer for operations on the spectrum
C   - IOSPEC() contains original spectrum
C   - ICUTOF() contains coarse baseline for use as cutoff limits in baseline
C              subtraction
C   - FREQS() contains the point frequencies
C   - ISPINT() contains interpolated points
C   - FREINT() contains interpolated frequencies
C
      USE DFLIB
C
      LOGICAL*2 true
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (TRUE=.TRUE.,intpt=1024,maxpk=500)
c
c     0 - black         4 - dark red        8 - dark grey    12 - red
c     1 - dark blue     5 - dark purple     9 - blue         13 - purple
c     2 - dirty green   6 - dirty yellow   10 - green        14 - yellow
c     3 - blue/green    7 - grey           11 - light blue   15 - white
c
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1)
      PARAMETER (nhelpc=0, nhelpb=7)
      RECORD /rccoord/curPos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
c
      INTEGER*2 IK,N,NFIT,IYCUT,IBASE
      INTEGER*2 maxx,maxy,linofs,mymode,myrows,mycols
      INTEGER*4 ISPEC(MAXPTS),NPTS,ISMALL,ILARGE,ISPINT(intpt)
      INTEGER*4 IOSPEC(maxpts),itemp(maxpts),icutof(maxpts)
      INTEGER*2 dummy,inkey
      REAL*8 FREQS(MAXPTS),ymeano,FREINT(intpt),a0,a1,freq,fapp,
     *       baslev,hwl,hwu,fwhh,shiftf
      INTEGER*4 dummy4,NAPP,iabase
      REAL*8 RSMALL,RLARGE,RANGE,ymean,f,x1,x2,y1,y2,delx,dely,rtemp
      REAL*8 XFIT(maxpk),YFIT(maxpk),XPEAK,ERRORX,YPEAK
      REAL*8 YSHIFT,YYSTEP,RRSMAL,RSPEC,ycord,ycent,xcent,fincr,
     *       rplus,rminus,flapp,fuapp,fiapp,FSTSP,FENSP,FINSP
      REAL*8 fmark,fstart,fend,fmean,flast,fchang,frange,flast1,flast2,
     *       elast1,elast2,basapp
      CHARACTER OUTSTR*22,FILNAM*50,kk,filgen*50,filapp*50
      CHARACTER*80 toplin,emplin,paslin,FREQLIN,botlin
      character coment*72,sample*20,lamp*6,scansp*6
C
      COMMON /FRE/FREQS
      COMMON /limits/wxy,maxx,maxy,linofs,curpos,ixy,
     * mymode,myrows,mycols
      COMMON /SPEC/ISPEC,NPTS,ISMALL,ILARGE
      COMMON /lines/toplin,emplin,paslin,botlin
      COMMON /FRFIT/XFIT,YFIT
      COMMON /FNAM/FILNAM
      COMMON /plotda/RSMALL,RLARGE,RRSMAL,YYSTEP,YSHIFT
      common /bufers/iospec,itemp,icutof
      common /intpol/freint,ispint
      COMMON /FLIMIT/FSTSP,FENSP,FINSP
      COMMON  /INFOC/COMENT,SAMPLE,LAMP,SCANSP
C
      itxt=1
      NFIT=7
      RSMALL=real(ISMALL)-0.05*(ilarge-ismall)
      RLARGE=real(ILARGE)+0.05*(ilarge-ismall)
      ymean=0.25*(rlarge-rsmall)+rsmall
      ymeano=ymean
      rtemp=0.0D0
      do 53 i=1,npts
        iospec(i)=ispec(i)
        rtemp=rtemp+ispec(i)
53    continue
      baslev=rtemp/real(npts)
c
      WRITE(botlin,601)
601   FORMAT('A-S  Q-E  Z-W  2-3    K-L              ',
     * '                                  H=help ')
C
C...Preparations of graphics for plotting
C
      fstart=freqs(1)
      fincr=(freqs(npts)-fstart)/(npts-1)
      if(npts.lt.maxx+1)then
        fend=freqs(npts)
        do 55 n=npts+1,maxx+1
          ispec(n)=ispec(npts)
          freqs(n)=FSTART+(N-1)*FINCR
55      continue
      else
        fend=freqs(maxx+1)
      endif
      fmark=(fstart+fend)*0.5d0
C
C...definition of pixel limits for the graphics viewport to allow erasure
C   of graphics leaving the top and bottom text lines
C   (note that pixel origin is now moved to the corner of the viewport)
C
3333  dummy4=setbkcolor(ntextb)
      call setviewport(2,2*LINOFS-2,maxx-2,maxy-2*LINOFS+2)
      call clearscreen($GCLEARSCREEN)
C
C----------------------------------------------------
C
C...A COMPLETE refresh of plot takes place from here
C   (the bottom of the graphics is set lower to RRSMAL than the range of
C    the data RSMALL to make space for the marker plot and label line)
C
C   Y-axis of spectrum spans 500 YYSTEP units when myrows=30 or 
C                            250 YYSTEP units when myrows=17
C   marker horizontal line is at RRSMAL
C   markers are 5 and 13 YYSTEP units down from RRSMAL
C
C...bottom information line
c
333   dummy=SETTEXTCOLOR(ntextc)
      dummy4= setbkcolor(ntextb)
      dummy=displaycursor($gcursoroff)
      CALL settextposition(myrows,1,curpos)
      CALL outtext(botlin(1:79))
      DUMMY=SETTEXTCOLOR(12)
      CALL settextposition(myrows,41,curpos)
      if(len_trim(filnam).le.30)then
        CALL outtext(filnam(1:30))
      else
        nc=len_trim(filnam)
        call outtext('...'//filnam(nc-27:nc))
      endif
C
C...declare new floating point bounds for graphics and clear the viewport
c   (top and bottom information lines will not be cleared)
C
33    YYSTEP=1.d0/500.d0*(RLARGE-RSMALL)
      if(myrows.eq.17)yystep=yystep*2.d0
      RRSMAL=RSMALL-13.d0*YYSTEP
      NSTART=1+nint( (fstart-freqs(1))/(freqs(npts)-freqs(1))*(npts-1))
      NEND  =1+nint( (fend  -freqs(1))/(freqs(npts)-freqs(1))*(npts-1))
331   if(nstart.lt.1)nstart=1
      if(nend.gt.npts)nend=npts
      if(nend-nstart.lt.3)then
        nstart=nstart-1
        nend=nend+1
        goto 331
      endif
      fstart=freqs(nstart)
      fend=freqs(nend)
      fincr=(FEND-FSTART)/DBLE(maxx)
      dummy=setwindow(TRUE,FSTART,RRSMAL,FEND,RLARGE)
      CALL setlinestyle(#FFFF)
      dummy=setcolor(nplotc)
      dummy4=setbkcolor(nplotb)
      dummy=setwritemode($GPSET)
      CALL clearscreen($GVIEWPORT)
c
c...box
c
      YSHIFT=RSMALL
      CALL  moveto_w(FSTART,RLARGE,wxy)
      dummy=lineto_w(FSTART,YSHIFT)
      dummy=lineto_w(FEND,YSHIFT)
      dummy=lineto_w(FEND,RLARGE)
      dummy=lineto_w(FSTART,RLARGE)
c
c...spectrum
c
      nmult=1
      if(nend-nstart.lt.intpt/2)then
        call interp(fstart,fend,nstart,nend,nplot,nmult)
        DO 16 I=1,nplot
          RSPEC=DBLE(ISPINT(i))
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.1)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREINT(i),RSPEC)
          endif
16      CONTINUE
      else
        DO 6 I=NSTART,NEND
          RSPEC=DBLE(ISPEC(i))
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.nstart)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREQS(i),RSPEC)
          endif
6       CONTINUE
      endif
C
c...draw the cursor
C
697   dummy=setwritemode($GXOR)
      dummy=setcolor(14)
      CALL moveto_w(fmark,RLARGE,wxy)
      dummy=lineto_w(fmark,YSHIFT)
      dummy=setcolor(15)
      dummy=setwritemode($GPSET)

c      open(4,file='dump',status='unknown')
c      do 5555 i=nstart,nend
c        write(4,'(i7,f15.4,i10)')i,freqs(i),ispec(i)
c5555  continue
c      write(4,'(1x)')
c      if(nplot.gt.1)then
c      do 5556 i=1,nplot
c        write(4,'(i7,f15.4,i10)')i,freint(i),ispint(i)
c5556  continue
c      endif
c      close(4)
C
C...Frequency marker scale and labels
C
777   call marsca(fstart,fend)
C
C
c.....O P T I O N S    L O O P
c
c...update the top two screen information lines
c
77    DUMMY=SETTEXTCOLOR(ntextc)
      dummy4= setbkcolor(ntextb)
      NSTART=1+nint( (fstart-freqs(1))/(freqs(npts)-freqs(1))*(npts-1))
      NEND  =1+nint( (fend  -freqs(1))/(freqs(npts)-freqs(1))*(npts-1))
      if(nstart.lt.1)nstart=1
      if(nend.gt.npts)nend=npts
      marker=1+nint( (fmark-freqs(1))/(freqs(npts)-freqs(1))*(npts-1) )
      WRITE(toplin,600)MARKER,fmark,NSTART,NEND 
600   FORMAT(' X:',I7,3X,F12.4,'  <- Cursor',8x,
     * 'Display limits -> X:',I7,I8)
      CALL settextposition(1,1,curpos)
      CALL outtext(toplin)
      WRITE(freqlin,602)ispec(marker),INT(RSMALL),INT(RLARGE)
602   FORMAT(' Y:',i7,52x,'Y:',I7,I8)
      CALL settextposition(2,1,curpos)
      CALL outtext(freqlin)
      justme=0
      dummy=settextcolor(15)
C
C   Options:  A,S - shift screen window over the spectrum
C             Q,E - X-axis zoom
C             W,Z - Y-axis zoom
C             2,3 - shift spectrum down/up
C             K,L - move cursor over the spectrum

C             ,   - center/quarter cursor
C             <HOME> <END> - move to beginning/end of spectrum
C             - - invert Y-axis
C             P - show spectral data points
C             F - frequency limits for display
C             ^ - toggle window height between 30 and 17 rows
C
C             B - baseline subtraction
C             N - smoothing
C             M - write current spectrum to file
C             R - restore initial screen
C             G - gle graphics
C             & - merge spectra
C
C             O - frequency of the line peak selected by cursor
C             0 - number of points for frequency determination / peakfinder
C             9 - use cursor position as peak frequency / baseline level
C             = - average of last two frequencies
C
C             H - display HELP screen
C             I - display spectral information
C
7     IK=INKEY(N)
      KK=CHAR(IK)
      IF(KK.EQ.'A'.OR.KK.EQ.'a')GOTO 36
      IF(KK.EQ.'S'.OR.KK.EQ.'s')GOTO 35
      IF(KK.EQ.'E'.OR.KK.EQ.'e')GOTO 50
      IF(KK.EQ.'Q'.OR.KK.EQ.'q')GOTO 100
      IF(KK.EQ.'W'.OR.KK.EQ.'w')GOTO 800
      IF(KK.EQ.'Z'.OR.KK.EQ.'z')GOTO 820
      IF(KK.EQ.'3'.OR.KK.EQ.'#')GOTO 60
      IF(KK.EQ.'2'.OR.KK.EQ.'@')GOTO 61
      IF(KK.EQ.'-'.OR.KK.EQ.'_')goto 970
      IF(KK.EQ.'F'.OR.KK.EQ.'f')GOTO 22
c
      IF(KK.EQ.'K'.OR.KK.EQ.'k')GOTO 710
      IF(KK.EQ.'L'.OR.KK.EQ.'l')GOTO 711
      IF(KK.EQ.',')GOTO 750
c
      IF(KK.EQ.'B'.OR.KK.EQ.'b')GOTO 830
      IF(KK.EQ.'N'.OR.KK.EQ.'n')GOTO 850
      IF(KK.EQ.'M'.OR.KK.EQ.'m')GOTO 870
c
      IF(KK.EQ.'H'.OR.KK.EQ.'h')GOTO 630
      IF(KK.EQ.'I'.OR.KK.EQ.'i')GOTO 640     
      IF(KK.EQ.'O'.OR.KK.EQ.'o')goto 940
      If(KK.eq.')'.OR.KK.EQ.'0')GOTO 902
      IF(KK.EQ.'9'.OR.KK.EQ.'(')goto 950
      IF(KK.EQ.'='.OR.KK.EQ.'+')goto 960
      if(KK.eq.'^')then
        call nargr
        goto 3333
      endif
      IF(KK.EQ.'&')GOTO 980
c
c...gle output
c
      IF(KK.EQ.'G'.or.KK.eq.'g')then
        DUMMY= SETTEXTCOLOR(ntextc)
        dummy4 = setbkcolor(ntextb)
        call clearscreen($GCLEARSCREEN)
        call gleout(fstart,fend,YSHIFT,RLARGE)
        GOTO 333
      ENDIF
C
C...restore original spectrum and scaling (with R)
C
      IF(KK.EQ.'R'.OR.KK.EQ.'r')THEN
        do 1100 i=1,npts
          ispec(i)=iospec(i)
1100    continue
        GOTO 33
      ENDIF
C
c...go to beginning of spectrum (with <HOME>)
c
      IF(IK.EQ.-71)THEN
        fstart=freqs(1)
        fend=fstart+maxx*fincr
        fmark=(fstart+fend)/2.d0
        GOTO 33
      ENDIF
C
c...go to end of spectrum (with <END>)
c
      IF(IK.EQ.-79)THEN
        fend=freqs(npts)
        fstart=fend-maxx*fincr
        if(fstart.lt.freqs(1))then
          fstart=freqs(1)
          fend=fstart+maxx*fincr
        endif
        fmark=(fstart+fend)/2.d0
        GOTO 33
      ENDIF
c
C
c...show spectral data points (with P)
c
      IF(KK.EQ.'P'.or.KK.eq.'p')THEN
        dely=     (5.0/maxy)*(rlarge-rsmall)
        delx=0.75*(5.0/maxx)*(freqs(nend)-freqs(nstart))
        DO 56 I=NSTART,NEND
          RSPEC=DBLE(Ispec(i))
          if(rspec.lt.rsmall)goto 56
          if(rspec.gt.rlarge)goto 56
          f=freqs(i)
          X1=f-DELX
          Y1=rspec+DELY
          X2=f+DELX
          Y2=rspec-DELY
          dummy=ellipse_w($GFILLINTERIOR,X1,Y1,X2,Y2)
56      CONTINUE
        GOTO 7
      ENDIF
c
      IF(IK.NE.13)GOTO 7
C
C...exit
C
      DUMMY= SETTEXTCOLOR(ntextc)
      dummy4 = setbkcolor(ntextb)
      CALL settextposition(2,1,curpos)
      CALL outtext(emplin)
      CALL settextposition(1,1,curpos)
      CALL outtext(emplin)
      DUMMY=SETTEXTCOLOR(15)
      dummy4=setbkcolor (12)
      WRITE(OUTSTR,'(A)')' ARE YOU SURE (Y/N) ? '
      CALL settextposition(1,1,curpos)
      CALL outtext(outstr)
916   IK=INKEY(N)
      KK=CHAR(IK)
      IF(KK.EQ.'Y'.OR.KK.EQ.'y')GOTO 37
      IF(KK.NE.'N'.AND.KK.NE.'n')GOTO 916
C
      DUMMY= SETTEXTCOLOR(ntextc)
      dummy4 = setbkcolor(ntextb)
      CALL settextposition(1,1,curpos)
      CALL outtext(toplin)
      CALL settextposition(2,1,curpos)
      CALL outtext(emplin)
      GOTO 7
C
C...Shift screen window to right of spectrum (with S)
C
35    rspec=fstart
      FRange=fend-fstart
      Fchang=FRange*0.5D0
      IF(KK.EQ.'s')Fchang=FRange*0.1D0
      fstart=fstart+Fchang
      fend=fend+Fchang
      IF(fend.gt.freqs(npts))THEN
        fend=freqs(npts)
        CALL settextposition(1,int2(itxt+1),curpos)
        fstart=fend-frange
      ENDIF
      FMARK=FMARK+(fstart-rspec)
      goto 33
C
C...Shift screen window to left of spectrum (with A)
C
36    FRange=fend-fstart
      Fchang=FRange*0.5D0
      IF(KK.EQ.'a')Fchang=FRange*0.1D0
      fstart=fstart-Fchang
      IF(fstart.LT.freqs(1))THEN
        fstart=freqs(1)
        Fchang=fend-(fstart+FRange)
        CALL settextposition(1,int2(itxt+1),curpos)
      ENDIF
      fend=fend-Fchang
      FMARK=FMARK-Fchang
      GOTO 33
C
C...Shift cursor to the left (with K)
C
710   dummy=setwritemode($GXOR)
      dummy=setcolor(14)
      CALL moveto_w(fmark,RLARGE,wxy)
      dummy=lineto_w(fmark,YSHIFT)
      fmark=fmark-8.d0*fincr
      IF(KK.EQ.'k')fmark=fmark+7.d0*fincr
      IF(fmark.LT.fstart+fincr)fmark=fstart+fincr
C
719   CALL moveto_w(fmark,RLARGE,wxy)
      dummy=lineto_w(fmark,YSHIFT)
      dummy=setcolor(15)
      dummy=setwritemode($GPSET)
c
      dummy=SETTEXTCOLOR(ntextc)
      marker=1+nint( (fmark-freqs(1))/(freqs(npts)-freqs(1))*(npts-1) )
      if(justme.eq.1)then
        WRITE(toplin,600)MARKER,fmark,NSTART,NEND
        CALL settextposition(1,1,curpos)
        CALL outtext(toplin)
        WRITE(freqlin,602)ispec(marker),INT(RSMALL),INT(RLARGE)
        CALL settextposition(2,1,curpos)
        CALL outtext(freqlin)
        justme=0
      else
        WRITE(outstr,603)MARKER,fmark
603     FORMAT(I7,3X,F12.4)
        CALL settextposition(1,4,curpos)
        CALL outtext(outstr(1:22))
        WRITE(outstr,605)ispec(marker)
605     FORMAT(I6)
        CALL settextposition(2,5,curpos)
        CALL outtext(outstr(1:6))
      endif
      GOTO 7
C
C...Shift cursor to the right (with L)
C
711   dummy=setwritemode($GXOR)
      dummy=setcolor(14)
      CALL moveto_w(fmark,RLARGE,wxy)
      dummy=lineto_w(fmark,YSHIFT)
      fmark=fmark+8.d0*fincr
      IF(KK.EQ.'l')fmark=fmark-7.d0*fincr
      IF(fmark.gT.fend-fincr)fmark=fend-fincr
      GOTO 719
C
C...Center cursor, on second keypress move the cursor into the center of the
C   opposite screenhalf (with ,)
C
750   dummy=setwritemode($GXOR)
      dummy=setcolor(14)
      CALL moveto_w(fmark,RLARGE,wxy)
      dummy=lineto_w(fmark,YSHIFT)
      fmean=(fend+fstart)/2.d0
      IF(fmark.EQ.Fmean)THEN
        IF(fLAST.LT.fmean)FMARK=FSTART+0.75*(fend-fstart)
        IF(fLAST.GE.fmean)FMARK=FSTART+0.25*(fend-fstart)
        fLAST=FMEAN
        GOTO 719
      ENDIF
      fLAST=fMARK
      fmark=fmean
      GOTO 719
c
c...zoom-in in frequency (with E)
c
50    FRange=Fend-Fstart
      Fchang=0.25D0*FRange
      IF(KK.EQ.'e')Fchang=0.45d0*FRange
      Fstart=Fmark-Fchang
      Fend=Fmark+Fchang
c
698   if(fstart.lt.freqs(1))fstart=freqs(1)
      if(fend.gt.freqs(npts))fend=freqs(npts)
      IF(FMARK.LT.fstart)FMARK=Fstart
      IF(FMARK.GT.fend)FMARK=Fend
c
801   fincr=(fend-fstart)/maxx
      GOTO 33
C
C...zoom-out in frequency (with Q)
C
100   FRange=Fend-Fstart
      Fchang=0.5D0*FRange
      IF(KK.EQ.'q')Fchang=0.1d0*FRange
      Fstart=Fstart-Fchang
      Fend=Fend+fchang
      GOTO 698
C
C...Y axis compression (with W)
C
800   IF(kk.eq.'W')THEN
        smult=-0.25
      ELSE
        smult=-0.05
      ENDIF
      goto 810
C
C...Y axis expansion (with Z)
C
820   IF(kk.eq.'Z')THEN
        smult=0.25
      ELSE
        smult=0.05
      ENDIF
810   RANGE=RLARGE-RSMALL
      RSMALL=YMEAN-0.25*RANGE*(1.+smult)
      RLARGE=YMEAN+0.75*RANGE*(1.+SMULT)
      GOTO 33
C
C...Y-axis shift upwards (with 3)
C
60    range=rlarge-rsmall
      if(kk.eq.'3')then
        range=-0.02*range
      else
        range=-0.10*range
      endif
63    ymean=ymean+range
      rsmall=rsmall+range
      rlarge=rlarge+range
      goto 33
C
C...Y-axis shift downwards (with 2)
C
61    range=rlarge-rsmall
      if(kk.eq.'2')then
        range= 0.02*range
      else
        range= 0.10*range
      endif
      goto 63
C
C...Y-axis reversal (with -)
C
970   do 971 nn=1,npts
        ispec(nn)=(rlarge-ispec(nn))+rsmall
971   continue
      baslev=(rlarge-baslev)+rsmall
      goto 33
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Frequency limits from keyboard (with F)
C
22    dummy4=setbkcolor(ntextb)
      DUMmy =settextcolor(ntextc)
      CALL clearscreen($GCLEARSCREEN)
      write(*,'(1x/''_____F R E Q U E N C Y   L I M I T S'',44(1H_)/)')
      WRITE(*,304)freqs(1),freqs(npts),freqs(npts)-freqs(1),
     *            fstart,fend,fend-fstart,fmark
304   FORMAT(34x,'   upper       lower           range'//
     *       '  Frequency limits of data:       ',2F12.3,f16.3/
     *       '  Frequency limits of display:    ',2F12.3,f16.3/
     *       '  Frequency of cursor:            ',6x,f12.3///
     * '  Specify new display limits  1/ ENTER keeps previous value'/
     * 30x,'2/ -ve lower limit moves cursor'/
     * 30x,'3/ -ve upper limit changes range'/)
302   WRITE(*,300)' Lower frequency display limit:  ',fstart
300   FORMAT(1X,A,F12.3,' -->  ',\)
      READ(*,'(f20.0)',ERR=302)FF1
      IF(FF1.lt.0.d0)then
        FF1=-FF1
        f=0.5d0*(fend-fstart)
        if(ff1.gt.freqs(npts))ff1=freqs(npts)-f
        if(ff1.lt.freqs(1))ff1=freqs(1)+f
        fstart=ff1-f
        fend=ff1+f 
        fmark=ff1      
        CALL clearscreen($GCLEARSCREEN)
        GOTO 333
      endif
      IF(FF1.LT.0.D0.OR.FF1.GT.freqs(npts))GOTO 302
      IF(FF1.gt.0.d0)fstart=FF1
c
303   WRITE(*,300)' Upper frequency display limit:  ',fend
      READ(*,'(f20.0)',ERR=303)FF2
      IF(FF2.LT.0.d0)then
        FF2=-FF2
        f=0.5d0*FF2
        fstart=fmark-f
        fend=fmark+f
        CALL clearscreen($GCLEARSCREEN)
        GOTO 333      
      ENDIF
      If(ff2.ne.0.0d0)then
        IF(FF2.LE.fstart.OR.FF2.LT.freqs(1))GOTO 303
        fend=FF2
      else
        if(fend.le.fstart)goto 303
      endif
      FMARK=0.5D0*(fstart+fend)
      dummy4=setbkcolor(ntextb)
      CALL clearscreen($GCLEARSCREEN)
      GOTO 333
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Background subtraction (with B)
C
830   DUMMY=SETTEXTCOLOR( int2(nhelpc) )
      dummy4= setbkcolor(      nhelpb)
      CALL clearscreen($GCLEARSCREEN)
      dummy=displaycursor($gcursoron)
      iycutl=0
      iycutu=0
      call smooth(2,iycutl,iycutu,nspt)
c
c...plot the original spectrum
c
      dummy=displaycursor($gcursoroff)
      CALL clearscreen($GCLEARSCREEN)
      dummy=setcolor(1)
      DO 1101 I=NSTART,NEND
        RSPEC=DBLE(Iospec(i))
        IF(RSPEC.gt.rlarge)rspec=rlarge
        if(rspec.lt.yshift)rspec=yshift
        if(i.eq.nstart)then
          CALL moveto_w(fstart,rspec,wxy)
        else
          dummy=lineto_w(FREQS(i),RSPEC)
        endif
1101  CONTINUE
      icolor=10
      dummy=setcolor(10)
C
C...select cutoff bounds if required
C
      if(iycutl.eq.-1.and.iycutu.eq.-1)then
        iystep=(rlarge-yshift)/maxy
        if(iystep.eq.0)iystep=1
        iycutu= 20*iystep
        iycutl=-500*iystep
C
C...upper cutoff
C
        DUMMY=SETTEXTCOLOR(12)
        dummy=setwritemode($GXOR)
        nstep=3*(1+(nend-nstart)/maxx)
        if(nstep.lt.1)nstep=1
C
        DO 3101 I=NSTART,NEND,nstep
          RSPEC=DBLE(Icutof(i)+iycutu)
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.nstart)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREQS(i),RSPEC)
          endif
3101    CONTINUE
C
        write(outstr,'(''Upper cutoff ='',i7)')iycutu
        CALL settextposition(1,2,curpos)
        CALL outtext(
     *    outstr(1:21)//', set with W,Z keys, terminate with ENTER')
5021    ik=inkey(n)
        kk=char(ik)
        if(ik.eq.13)goto 5020
        icutol=iycutu
        if(kk.eq.'Z'.or.kk.eq.'z')then
          iycutu=iycutu-iystep
          if(kk.eq.'Z')iycutu=iycutu-9*iystep
          if(iycutu.lt.iycutl+3*iystep)iycutu=iycutl+3*iystep
          goto 5022
        endif
        if(kk.eq.'W'.or.kk.eq.'w')then
          iycutu=iycutu+iystep
          if(kk.eq.'W')iycutu=iycutu+4*iystep
C         if(iycutu.gt.rlarge)iycutu=rlarge
          goto 5022
        endif
C        if(kk.eq.'c'.or.kk.eq.'C')then
C          icolor=icolor+1
C     if(icolor.eq.16)icolor=0
C          dummy=setcolor(icolor)
C   endif

        goto 5021
C
5022    DO 3102 I=NSTART,NEND,nstep
          RSPEC=DBLE(Icutof(i)+icutol)
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.nstart)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREQS(i),RSPEC)
          endif
3102    CONTINUE
        DO 3103 I=NSTART,NEND,nstep
          RSPEC=DBLE(Icutof(i)+iycutu)
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.nstart)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREQS(i),RSPEC)
          endif
3103    CONTINUE
C
        write(outstr,'(''Upper cutoff ='',i7)')iycutu
        CALL settextposition(1,2,curpos)
        CALL outtext(outstr(1:21))
        goto 5021
C
C...lower cutoff
C
5020    iycutl=iycutu-20*iystep
        DO 3104 I=NSTART,NEND,nstep
          RSPEC=DBLE(Icutof(i)+iycutl)
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.nstart)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREQS(i),RSPEC)
          endif
3104    CONTINUE
C
        write(outstr,'(''Lower cutoff ='',i7)')iycutl
        CALL settextposition(1,2,curpos)
        CALL outtext(outstr(1:21))
5023    ik=inkey(n)
        kk=char(ik)
        if(ik.eq.13)goto 5025
        icutol=iycutl
        if(kk.eq.'Z'.or.kk.eq.'z')then
          iycutl=iycutl-iystep
          if(kk.eq.'Z')iycutl=iycutl-9*iystep
C         if(iycutl.lt.yshift)iycutl=yshift
          goto 5024
        endif
        if(kk.eq.'W'.or.kk.eq.'w')then
          iycutl=iycutl+iystep
          if(kk.eq.'W')iycutl=iycutl+4*iystep
          if(iycutl.gt.iycutu-3*iystep)iycutl=iycutu-3*iystep
          goto 5024
        endif
        goto 5023
5024    DO 3105 I=NSTART,NEND,nstep
          RSPEC=DBLE(Icutof(i)+icutol)
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.nstart)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREQS(i),RSPEC)
          endif
3105    CONTINUE
        DO 3106 I=NSTART,NEND,nstep
          RSPEC=DBLE(Icutof(i)+iycutl)
          IF(RSPEC.gt.rlarge)rspec=rlarge
          if(rspec.lt.yshift)rspec=yshift
          if(i.eq.nstart)then
            CALL moveto_w(fstart,rspec,wxy)
          else
            dummy=lineto_w(FREQS(i),RSPEC)
          endif
3106    CONTINUE
C
        write(outstr,'(''Lower cutoff ='',i7)')iycutl
        CALL settextposition(1,2,curpos)
        CALL outtext(outstr(1:21))
        goto 5023
c
5025    call smooth(3,iycutl,iycutu,nspt)
      endif
c
c...plot the smoothed spectrum
c
      dummy=setcolor(12)
      dummy=setwritemode($GPSET)
      if(iycutu.ne.iycutl)then
C       RSPEC=DBLE(Iycutu)
C       IF(RSPEC.gt.rlarge)rspec=rlarge
C       if(rspec.lt.yshift)rspec=yshift
C       CALL moveto_w(freqs(nstart),rspec,wxy)
C       dummy=lineto_w(FREQS(nend),rspec)

C       RSPEC=DBLE(Iycutl)
C       IF(RSPEC.gt.rlarge)rspec=rlarge
C       if(rspec.lt.yshift)rspec=yshift
C       CALL moveto_w(freqs(nstart),rspec,wxy)
C       dummy=lineto_w(FREQS(nend),rspec)
      endif
      DO 1102 I=NSTART,NEND
        RSPEC=DBLE(Itemp(i))
        IF(RSPEC.gt.rlarge)rspec=rlarge
        if(rspec.lt.yshift)rspec=yshift
        if(i.eq.nstart)then
          CALL moveto_w(fstart,rspec,wxy)
        else
          dummy=lineto_w(FREQS(i),RSPEC)
        endif
1102  CONTINUE
c
      iystep=(rlarge-yshift)/maxy
      rspec=yshift+5*iystep
      rplus=rspec+4*iystep
      rminus=rspec-4*iystep
      CALL moveto_w(freqs(nstart+5),rminus,wxy)
      dummy=lineto_w(FREQS(nstart+5),rplus)
      CALL moveto_w(freqs(nstart+5),rspec,wxy)
      dummy=lineto_w(FREQS(nstart+5+nspt),rspec)
      CALL moveto_w(freqs(nstart+5+nspt),rminus,wxy)
      dummy=lineto_w(FREQS(nstart+5+nspt),rplus)
c
      dummy=setcolor(15)
      DUMMY=SETTEXTCOLOR(nhelpc)
      CALL settextposition(1,1,curpos)
      CALL outtext(emplin(1:78))
      CALL settextposition(1,1,curpos)
      CALL outtext(' Press ENTER to continue')
1108  ik=inkey(n)
      if(ik.ne.13)goto 1108
c
1103  rtemp=0.d0
      do 1106 i=1,npts
        ispec(i)=ispec(i)+ymean
        rtemp=rtemp+ispec(i)
1106  continue
      baslev=rtemp/npts
      goto 333
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Smoothing (with N)
C
850   DUMMY=SETTEXTCOLOR( int2(nhelpc) )
      dummy4= setbkcolor(      nhelpb)
      CALL clearscreen($GCLEARSCREEN)
      dummy=displaycursor($gcursoron)
      CALL settextposition(1,1,curpos)
      call smooth(1,iycutl,iycutu,nspt)
      goto 333
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Output to file (with M)
C
870   DUMMY=SETTEXTCOLOR( int2(nhelpc) )
      dummy4= setbkcolor(      nhelpb)
      CALL clearscreen($GCLEARSCREEN)
      CALL settextposition(1,1,curpos)
      dummy=displaycursor($gcursoron)
      call savesp
      goto 333
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Append spectrum (with &)
C   to original, untransformed current spectrum
C
980   do 981 i=1,npts
        ispec(i)=iospec(i)
981   continue
      nptso=npts
      ymean=ymeano
C
C...Open and read appended spectrum
C
985   DUMMY=SETTEXTCOLOR( int2(ntextc) )
      dummy4= setbkcolor(      ntextb)
      CALL clearscreen($GCLEARSCREEN)
      CALL settextposition(1,1,curpos)
      dummy=displaycursor($gcursoron)
C
      do 982 nc=len_trim(filnam),1,-1
        if(filnam(nc:nc).eq.'\')goto 983
982   continue
983   if(nc.eq.0.or.nc.eq.1)then
        filgen=''
      else
        filgen=filnam(1:nc)
      endif
c
      WRITE(*,984)
984   format(1X/'_____A P P E N D   S P E C T R U M',46(1h_)//)
C
      write(*,990)filnam
990   format(1x/5x,'Specify name of spectrum to be appended - ',
     *    'do not type the path, which is'/
     *    5x,'implied by the current spectrum (or press ENTER to exit)'/
     *   /5x,' Current spectrum:  ',a/
     *    5x,'   To be appended:  ',$)
      read(*,'(a)',err=985)outstr
      dummy=displaycursor($gcursoroff)
      if(len_trim(outstr).eq.0)goto 333
c      
      filapp=filgen(1:len_trim(filgen))//outstr(1:len_trim(outstr))
      OPEN(2,FILE=FILAPP,FORM='BINARY',STATUS='OLD',ERR=985)
      read(2,end=986,err=986)(outstr(1:18),i=1,4)
      read(2,end=986,err=986)(dummy,i=1,6)
      read(2,end=986,err=986) outstr(1:6)
      read(2,end=986,err=986)(dummy4,i=1,3)
      read(2,end=986,err=986) outstr(1:20)      
      read(2,end=986,err=986)(dummy4,i=1,4)
      read(2,end=986,err=986) outstr(1:6)
      read(2,end=986,err=986)(dummy4,i=1,3)
      read(2,end=986,err=986) dummy
      if(dummy.eq.-1)then
        read(2,end=986,err=986)dummy4
        napp=dummy4
      else
        napp=dummy
        read(2,end=986,err=986)dummy4
      endif
      if(napp.lt.10)goto 986
      basapp=0.d0
      DO 20 NN=1,napp
        READ(2,end=986,err=986)dummy
        IOSPEC(NN)=dummy
        basapp=basapp+dummy
20    CONTINUE
      basapp=basapp/real(napp)
      read(2,end=986,err=986)flapp,fuapp,fiapp
c
      fuapp=flapp+(napp-1)*fiapp
      close(2)
c
      if(fuapp-fensp.lt.2.*finsp)then
        DUMMY=SETTEXTCOLOR(12)
        write(*,993)
993     FORMAT(1x//5x,'SORRY - Prepending or merging of spectra is not ',
     *    'possible'/)
        DUMMY=SETTEXTCOLOR(ntextc)
        write(*,'(1x/5x,''Press ENTER to continue'',$)')
1011    ik=inkey(n)
        if(ik.ne.13)goto 1011
        goto 986
      endif
c
      write(*,987)npts,freqs(1),freqs(npts),finsp,
     *            napp,flapp,fuapp,fiapp
987   format(1x//20x,'Npts',10x,'Fstart',10x,'Fend',9x,'Fstep'//
     *  5x,' Current:  ',i8,2x,2F14.4,f14.6/
     *  5x,'Appended:  ',i8,2x,2F14.4,f14.6/)
      goto 988   
c
c...exit on error
c
986   close(2)
      do 1006 i=1,npts
        iospec(i)=ispec(i)
1006  continue
      goto 985
c      
c...convert appended spectrum to the frequency grid of the current spectrum
c
988   i=npts+1
      freq=FREQS(i-1)+FINSP
      iapp=1
      fapp=FLAPP+(iapp-1)*FIAPP
C     
C...skip overlapping points, if any
C
1007  if(freq-fapp.gt.fiapp)then
        iapp=iapp+1
        fapp=FLAPP+(iapp-1)*FIAPP
        goto 1007
      endif
      if(iapp.gt.1)then
        write(*,'(i8,'' points from the appended spectrum '',
     *     ''have been skipped''/)')iapp-1
      endif
C
C...insert dummy points to fill break between the two spectra, if there is one
C
1008  if(freq-fapp.lt.0.d0)then
        freqs(i)=freq
        ispec(i)=iospec(1)
        i=i+1
        freq=FREQS(i-1)+FINSP
        if(i.gt.maxpts)then
          do 1009 i=1,npts
           iospec(i)=ispec(i)
1009      continue
          goto 985
        endif
        goto 1008
      endif
      if(i-nptso.gt.1)then 
        nappt=i-nptso-1
        ifrsta=i
        write(*,'(i8,'' dummy points inserted between current '',
     *  ''and appended spectrum''/)')i-nptso-1
      endif     
C
C...main interpolation loop
C
994   freqs(i)=freq
      ispec(i)=iospec(iapp)+(freq-fapp)*
     *                     (iospec(iapp+1)-iospec(iapp))/fiapp
C
      i=i+1
      freq=FREQS(i-1)+FINSP
      if(freq.gt.fuapp)then
        npts=i-1
        goto 1003
      endif
      if(i.gt.maxpts)then
        npts=i-1
        DUMMY=SETTEXTCOLOR(12)
        write(*,'(5x,''The maximum number of'',i7,
     *    '' points has been reached''/)')maxpts
        DUMMY=SETTEXTCOLOR(ntextc)
        goto 1003
      endif
c
      if(freq-fapp.le.fiapp)then
        goto 994
      else          
        iapp=iapp+1
        fapp=FLAPP+(iapp-1)*FIAPP
        if(iapp.gt.napp)then
          npts=i-1
          goto 1003
        endif
        goto 994
      endif
C      
c...tidy up
c
1003  write(*,'(1x/5x,''Press ENTER to continue'',$)')
1010  ik=inkey(n)
      if(ik.ne.13)goto 1010
C
      do 992 i=1,npts
        iospec(i)=ispec(i)
992   continue        
      fmark=freqs(nptso)
      rtemp=200.d0*finsp
      fstart=fmark-rtemp
      fend=fmark+rtemp
      fstsp=freqs(1)
      fensp=freqs(npts)
c
c
c...graphically match end of current spectrum with beginning of 
c   the appended spectrum 
c      
      DUMMY=SETTEXTCOLOR(12)
      call settextposition(1,1,curpos)
      call outtext(emplin)
      call settextposition(2,1,curpos)
      call outtext(emplin)
      call settextposition(1,1,curpos)
      write(freqlin,'(a)')
     * ' Adjust Y-position of appended spectrum with W,Z keys, '//
     * 'terminate with ENTER'
      call outtext(freqlin)
C
      NSTART=1+nint( (fstart-freqs(1))/(freqs(npts)-freqs(1))*(npts-1))
      NEND  =1+nint( (fend  -freqs(1))/(freqs(npts)-freqs(1))*(npts-1))
      NCENT =1+nint( (fmark -freqs(1))/(freqs(npts)-freqs(1))*(npts-1))
      dummy=setcolor(1)
      dummy4=setbkcolor(ntextb)
      dummy=setwindow(TRUE,FSTART,RRSMAL,FEND,RLARGE)
      CALL clearscreen($GVIEWPORT)
      dummy=setwritemode($GPSET)
C
      dummy=setcolor(12)
      rspec=baslev
      CALL moveto_w(freqs(nstart),rspec,wxy)
      CALL lineto_w(freqs(ncent),rspec)
      dummy=setcolor(1)
c
      shiftf=0.d0
      nshift=0     
      DO 996 I=NSTART,NEND
        RSPEC=DBLE(ISPEC(i+nshift))
        IF(RSPEC.gt.rlarge)rspec=rlarge
        if(rspec.lt.yshift)rspec=yshift
        if(i.eq.nstart)then
          CALL moveto_w(fstart,rspec,wxy)
        else
          dummy=lineto_w(FREQS(i+nshift)-shiftf,RSPEC)
        endif
        if(I.eq.NCENT)then
          if(nappt.gt.20)then
            shiftf=freqs(ifrsta-10)-freqs(nptso)
            nshift=nappt-10
          endif
          dummy=setwritemode($GXOR)
          dummy=setcolor(10)                                            9
        endif
996   CONTINUE
      dummy=setcolor(12)
      CALL moveto_w(freqs(ncent),basapp,wxy)
      CALL lineto_w(freqs(nend),basapp)
      dummy=setcolor(10)                                                9
C
      iabase=0
      iyold=0
      goto 999 
C
C...up/down shift loop: erase old trace first
C
998   DO 1000 I=NCENT,NEND
        RSPEC=DBLE(ISPEC(i+nshift)+iyold)
        IF(RSPEC.gt.rlarge)rspec=rlarge
        if(rspec.lt.yshift)rspec=yshift
        if(i.eq.ncent)then
          RSPEC=DBLE(ISPEC(i+nshift))
          CALL moveto_w(fmark,rspec,wxy)
        else
          dummy=lineto_w(FREQS(i+nshift)-shiftf,RSPEC)
        endif
1000  CONTINUE
C
      dummy=setcolor(12)
      rspec=basapp+dble(iyold)
      CALL moveto_w(freqs(ncent),rspec,wxy)
      CALL lineto_w(freqs(nend),rspec)
      dummy=setcolor(10)                                                9
C
C...now draw the new trace
C
      iyold=iabase
      DO 1001 I=NCENT,NEND
        RSPEC=DBLE(ISPEC(i+nshift)+iabase)
        IF(RSPEC.gt.rlarge)rspec=rlarge
        if(rspec.lt.yshift)rspec=yshift
        if(i.eq.ncent)then
          RSPEC=DBLE(ISPEC(i+nshift))
          CALL moveto_w(fmark,rspec,wxy)
        else
          dummy=lineto_w(FREQS(i+nshift)-shiftf,RSPEC)
        endif
1001  CONTINUE
C
      dummy=setcolor(12)
      rspec=basapp+dble(iabase)
      CALL moveto_w(freqs(ncent),rspec,wxy)
      CALL lineto_w(freqs(nend),rspec)
      dummy=setcolor(10)                                                9
C
C...select options
C
999   IK=INKEY(N)
      KK=CHAR(IK)
      if(KK.eq.'z'.or.kk.eq.'Z')then
        iabase=iabase-(rlarge-rsmall)/real(maxy)
        if(kk.eq.'Z')iabase=iabase-9.*(rlarge-rsmall)/real(maxy)
c       if(iabase.lt.rsmall)iabase=rsmall
        goto 998
      endif
      if(KK.eq.'W'.or.kk.eq.'w')then
        iabase=iabase+(rlarge-rsmall)/real(maxy)
        if(kk.eq.'W')iabase=iabase+9.*(rlarge-rsmall)/real(maxy)
c       if(iabase.gt.rlarge)iabase=rlarge
        goto 998
      endif
      if(ik.ne.13)goto 999
c
      do 1002 i=nptso+1,npts
        ispec(i)=ispec(i)+iabase
        iospec(i)=iospec(i)+iabase
1002  continue        
c
      coment=' Merged spectrum'
      goto 333
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
c...use current cursor position for current frequency (with 9)
c
950   flast2=flast1
      flast1=fmark
      elast2=elast1
      elast1=0.d0
      WRITE(FREQlin,951)fmark
951   FORMAT('    Cursor frequency = ',F14.4,
     * '  taken as measured frequency')
      DUMMY=SETTEXTCOLOR(      1 )
      dummy4= setbkcolor( ntextb )
      CALL settextposition(1,1,curpos)
      CALL outtext(freqlin)
      if(nmult.gt.1)then
        i=1+nint( (fmark-fstart)/(fend-fstart)*(nplot-1) )
        if(i.eq.0)i=1
        if(i.gt.nplot)i=nplot
        baslev=ispint(i)
      else
        i=nstart+nint(real(nend-nstart)*(fmark-fstart)/(fend-fstart))
        if(i.gt.npts)i=npts
        baslev=ispec(i)
      endif
      WRITE(FREQlin,952)baslev
952   FORMAT('    Cursor ordinate  = ',F14.4,
     * '  taken as new baseline level')
      CALL settextposition(2,1,curpos)
      call outtext(freqlin)
      justme=1
      goto 7
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
c
c...average of the last two measured peak frequencies (with =)
c
960   fmean=0.5d0*(flast1+flast2)
      emean=dsqrt(elast1**2+elast2**2)
      WRITE(FREQlin,961)fmean,emean,flast1
961   FORMAT('    Average frequency = ',F14.4,' +-',F7.4,
     *       11x,'Line1 =',F13.4)
      DUMMY=SETTEXTCOLOR(      1 )
      dummy4= setbkcolor( ntextb )
      CALL settextposition(1,1,curpos)
      CALL outtext(freqlin)
      WRITE(FREQlin,962)abs(flast1-flast2),emean,flast2
962   FORMAT(' Difference frequency = ',F14.4,' +-',F7.4,
     *       11x,'Line2 =',F13.4)
      CALL settextposition(2,1,curpos)
      call outtext(freqlin)
      justme=1
      goto 7
c
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C   Set the number of points for determining line frequencies (with 0)
C   -ve number executes PEAKFINDER
C
C   This number always refers to uninterpolated points in the original data
C
902   DUMMY=SETTEXTCOLOR( int2(     1) )
      dummy4= setbkcolor(      ntextb)
      CALL settextposition(1,1,curpos)
      call outtext(emplin)
      call settextposition(2,1,curpos)
      call outtext(emplin)
      call settextposition(1,1,curpos)
      WRITE(*,905)NFIT
905   FORMAT(' Current no. of points for fitting lineshape: ',I3/
     *       '        New number (odd, -ve for PEAKFINDER):  ',$)
      READ(*,'(I5)',ERR=902)I
      IF((I.gt.-5.and.i.lt.3).OR.ABS(I).Ge.maxpk)GOTO 902
      IF(ABS(I).EQ.2*(ABS(I)/2))GOTO 902
      NFIT=ABS(I)
      IF(I.LT.0)GOTO 930
      GOTO 333
C
C
C  P E A K F I N D E R
C
c...determine background level
c
930   DUMMY=SETTEXTCOLOR(12)
      call settextposition(1,1,curpos)
      call outtext(emplin)
      call settextposition(2,1,curpos)
      call outtext(emplin)
      call settextposition(1,1,curpos)
      write(freqlin,'(a)')
     * ' Set the baseline level with W,Z keys, terminate with ENTER'
      call outtext(freqlin)
      IBASE=baslev
      dummy=setwritemode($GXOR)
      dummy=setcolor(12)
      goto 5499
5500  CALL moveto_w(fstart,dble(iyold),wxy)
      dummy=lineto_w(fend,dble(iyold))
5499  iyold=ibase
      CALL moveto_w(fstart,dble(ibase),wxy)
      dummy=lineto_w(fend,dble(iBASE))
5501  IK=INKEY(N)
      KK=CHAR(IK)
      if(KK.eq.'z'.or.kk.eq.'Z')then
        ibase=ibase-(rlarge-rsmall)/maxy
        if(kk.eq.'Z')ibase=ibase-9.*(rlarge-rsmall)/maxy
        if(ibase.lt.rsmall)ibase=rsmall
        goto 5500
      endif
      if(KK.eq.'W'.or.kk.eq.'w')then
        ibase=ibase+(rlarge-rsmall)/maxy
        if(kk.eq.'W')ibase=ibase+9.*(rlarge-rsmall)/maxy
        if(ibase.gt.rlarge)ibase=rlarge
        goto 5500
      endif
      if(ik.ne.13)goto 5501
c
c...determine cutoff level
c
      call settextposition(1,1,curpos)
      call outtext(emplin)
      call settextposition(1,1,curpos)
      write(freqlin,'(a)')
     * ' Set the Y-axis cutoff with W,Z keys, terminate with ENTER'
      call outtext(freqlin)
      IYCUT=Ibase+10*(rlarge-rsmall)/maxy
      goto 5505
5502  CALL moveto_w(fstart,dble(iyold),wxy)
      dummy=lineto_w(fend,dble(iyold))
5505  iyold=iycut
      CALL moveto_w(fstart,dble(iycut),wxy)
      dummy=lineto_w(fend,dble(iycut))
5503  IK=INKEY(N)
      KK=CHAR(IK)
      if(KK.eq.'z'.or.kk.eq.'Z')then
        iycut=iycut-(rlarge-rsmall)/maxy
        if(kk.eq.'Z')iycut=iycut-9.*(rlarge-rsmall)/maxy
        if(iycut.le.ibase)iycut=ibase+(rlarge-rsmall)/maxy
        goto 5502
      endif
      if(KK.eq.'W'.or.kk.eq.'w')then
        iycut=iycut+(rlarge-rsmall)/maxy
        if(kk.eq.'W')iycut=iycut+9.*(rlarge-rsmall)/maxy
        if(iycut.gt.rlarge)iycut=rlarge
        goto 5502
      endif
      if(ik.ne.13)goto 5503
c
      DUMMY=SETTEXTCOLOR( int2(nhelpc) )
      dummy4= setbkcolor(      nhelpb)
      CALL AUTOPK(NSTART,NEND,IYCUT,IBASE,NFIT,rlarge-baslev)           <--- AUTOPK
      dummy=displaycursor($gcursoroff)
      dummy=setwritemode($GPSET)
      GOTO 333
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Frequency of line under the cursor (with O)
c
c   If the spectrum is interpolated then fitting width becomes NFIT*nmult and
c   points from FREINT,ISPINT are used
C
940   DUMMY=SETTEXTCOLOR(1)
      if(nmult*NFIT.lt.5)then
        write(freqlin,'(2a)')' ERROR: 3 point width allowed only',
     *   'on expanded data: increase X-expansion'
        GOTO 965
      endif
c
c...More precise starting point is derived by following the gradient from 
c   the marker position until the nearest turning point.
c   If marker is above the baseline then a maximum is searched for, and
c   a minimum if otherwise.
c
      if(nmult.eq.1)then
        mark=marker
        istep=isign(1,ispec(mark+1)-ispec(mark))
        if(ispec(mark).gt.baslev)then
941       mark=mark+istep
          iii=istep*(ispec(mark+1)-ispec(mark))
          if(iii.gt.0)goto 941
        else
          istep=-istep
944       mark=mark+istep
          iii=istep*(ispec(mark+1)-ispec(mark))
          if(iii.lt.0)goto 944
        endif
      else
        mark=1+nint( (fmark-fstart)/(fend-fstart)*(nplot-1) )
        istep=isign(1,ispint(mark+1)-ispint(mark))
        if(ispint(mark).gt.baslev)then
942       mark=mark+istep
          iii=istep*(ispint(mark+1)-ispint(mark))
          if(iii.gt.0)goto 942
        else
          istep=-istep
943       mark=mark+istep
          iii=istep*(ispint(mark+1)-ispint(mark))
          if(iii.lt.0)goto 943
        endif
      endif
C
C...measure line iteratively using the counter NROUND
C
      nround=0
907   I=0
      DO 904 III=-(nmult*NFIT)/2,(nmult*NFIT)/2,1
        I=I+1
        IIX=MARK+III
        IF(  (nmult.eq.1.and.(IIX.LT.1.OR.IIX.GT.NPTS )).or.
     *       (nmult.gt.1.and.(IIX.LT.1.OR.IIX.GT.nplot)) )THEN
          WRITE(FREQLIN,906)
906       FORMAT(' ERROR: fitting interval exceeds data bounds')
          GOTO 965
        ENDIF
        if(nmult.eq.1)then
          XFIT(I)=FREQS(IIX)
          YFIT(I)=ISPEC(IIX)
        else
          XFIT(I)=FREINT(IIX)
          YFIT(I)=ISPINT(IIX)
        endif
904   CONTINUE
C
      if(nmult*nfit.gt.maxpk)then
        write(freqlin,'(2a)')' ERROR: Too many points for peak ',
     *   'measurement: reduce X-expansion'
        GOTO 965
      endif
      CALL PEAKF(int2(nmult*NFIT),XPEAK,ERRORX,YPEAK,A0,A1)             <--- PEAKF
c
      nround=nround+1
      if(nround.le.3)then
        if(nmult.eq.1)then
          mark=nstart+
     *           nint(real(nend-nstart)*(xpeak-fstart)/(fend-fstart))
        else
          mark=1+nint( (xpeak-fstart)/(fend-fstart)*(nplot-1) )
        endif
        goto 907
      endif
c      
      flast2=flast1
      flast1=xpeak
      elast2=elast1
      elast1=errorx
c
c...refresh spectrum and cursor
c
      DUMMY=SETCOLOR(     int2(nplotc) )
      dummy4= setbkcolor(      nplotb  )
      CALL clearscreen($GVIEWPORT)
      DO 1105 I=NSTART,NEND
        RSPEC=DBLE(Ispec(i))
        IF(RSPEC.gt.rlarge)rspec=rlarge
        if(rspec.lt.yshift)rspec=yshift
        if(i.eq.nstart)then
          CALL moveto_w(fstart,rspec,wxy)
        else
          dummy=lineto_w(FREQS(i),RSPEC)
        endif
1105  CONTINUE
      dummy=setwritemode($GXOR)
      dummy=setcolor(14)
      CALL moveto_w(fmark,RLARGE,wxy)
      dummy=lineto_w(fmark,YSHIFT)
      dummy=setwritemode($GPSET)
c
c...plot results - the whole screen is redrawn here to plot only the
c   results for the current peak
c
      dummy=setcolor(nplotc)
      CALL  moveto_w(FSTART,RLARGE,wxy)
      dummy=lineto_w(FSTART,YSHIFT)
      dummy=lineto_w(FEND,YSHIFT)
      dummy=lineto_w(FEND,RLARGE)
      dummy=lineto_w(FSTART,RLARGE)
c
      call marsca(fstart,fend)
c
C...fitted parabola
c
      dummy=setwritemode($GPSET)
      dummy=setcolor(12)
      ycent=yfit((nmult*nfit)/2+1)
      xcent=xfit((nmult*nfit)/2+1)
      do 909 n=1,nmult*nfit
        rspec=xfit(n)+xcent
        if(n.eq.(nmult*nfit)/2+1)then
          ycord=ycent
          rspec=xcent
        else
          ycord=(a0+a1*xfit(n))*xfit(n)+ycent
        endif
        if(n.eq.1)then
          CALL  moveto_w(rspec,ycord,wxy)
        else
          dummy=lineto_w(rspec,ycord)
        endif
909   continue
c
c...halfwidth
c
      rtemp=0.5d0*(ypeak+baslev)
      if(nmult.gt.1)then
        i=1+nint( (xpeak-fstart)/(fend-fstart)*(nplot-1) )
        if(i.eq.0)i=1
        if(i.gt.nplot)i=nplot
        do 911 nn=i,2,-1
          if((ispint(nn)-rtemp)*(ispint(nn-1)-rtemp).gt.0.d0)goto 911
          hwl=freint(nn-1)+(rtemp-ispint(nn-1))*
     *           (freint(nn)-freint(nn-1))/real(ispint(nn)-ispint(nn-1))
          goto 913
911     continue
913     do 912 nn=i,nplot-1
          if((ispint(nn)-rtemp)*(ispint(nn+1)-rtemp).gt.0.d0)goto 912
          hwu=freint(nn)+(rtemp-ispint(nn))*
     *           (freint(nn+1)-freint(nn))/real(ispint(nn+1)-ispint(nn))
          goto 914
912     continue
      else
        i=nstart+nint(real(nend-nstart)*(xpeak-fstart)/(fend-fstart))
        if(i.gt.npts)i=npts
        do 917 nn=i,nstart+1,-1
          if((ispec(nn)-rtemp)*(ispec(nn-1)-rtemp).gt.0.d0)goto 917
          hwl=freqs(nn-1)+(rtemp-ispec(nn-1))*
     *              (freqs(nn)-freqs(nn-1))/real(ispec(nn)-ispec(nn-1))
          goto 918
917     continue
918     do 919 nn=i,nend-1
          if((ispec(nn)-rtemp)*(ispec(nn+1)-rtemp).gt.0.d0)goto 919
          hwu=freqs(nn)+(rtemp-ispec(nn))*
     *              (freqs(nn+1)-freqs(nn))/real(ispec(nn+1)-ispec(nn))
          goto 914
919     continue
      endif
914   fwhh=hwu-hwl
c
c...various vertical lines
c
      dummy=setcolor(11)
      CALL moveto_w(XPEAK,baslev,wxy)
      dummy=lineto_w(XPEAK,ypeak)
c
      CALL setlinestyle(#9999)
      dummy=setcolor(14)
      if(nmult.eq.1)then
        rplus=freqs(mark+nfit/2)
      else
        rplus=freint(mark+(nmult*nfit)/2)
      endif
      CALL moveto_w(rplus,RLARGE,wxy)
      dummy=lineto_w(rplus,YSHIFT)
c
      if(nmult.eq.1)then
        rminus=freqs(mark-nfit/2)
      else
        rminus=freint(mark-(nmult*nfit)/2)
      endif
      CALL moveto_w(rminus,RLARGE,wxy)
      dummy=lineto_w(rminus,YSHIFT)
      CALL setlinestyle(#FFFF)
c
c...various horizontal lines
c
      dummy=setcolor(11)
      CALL moveto_w(FSTART,baslev,wxy)
      dummy=lineto_w(FEND,baslev)
      CALL moveto_w(rminus,ypeak,wxy)
      dummy=lineto_w(rplus,ypeak)
c
      dummy=setcolor(14)
      CALL moveto_w(hwl,rtemp,wxy)
      dummy=lineto_w(hwu,rtemp)     
c
      call marsca(fstart,fend)
c
C...text results
c
      WRITE(FREQlin,903)XPEAK,ERRORX,ypeak-baslev
903   FORMAT(' Fitted peak frequency: ',F14.4,' +-',F7.4,9x,
     *  'Intensity:',F12.2)
c
965   DUMMY=SETTEXTCOLOR(      1 )
      dummy4= setbkcolor( ntextb )
      CALL settextposition(1,1,curpos)
      CALL outtext(FREQlin(1:80))
c
      CALL settextposition(2,1,curpos)
      if(freqlin(2:6).ne.'ERROR')then
        if(nmult.eq.1)then
          write(freqlin,915)FWHH,NFIT
        else
          write(freqlin,908)FWHH,nmult,NFIT
        endif
915     format('      Halfwidth (FWHH): ',F14.4,17x,
     *         'Data points:',I9)   
908     format('      Halfwidth (FWHH): ',F14.4,17x,
     *         'Data points:',I4,' *',i3)
        call outtext(freqlin(1:80))
      else
        call outtext(emplin)
      endif
C
      justme=1
      GOTO 7
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Help screen (with H)
C
630   DUMMY=SETTEXTCOLOR(nhelpc)
      dummy4= setbkcolor(nhelpb)
      CALL clearscreen($GCLEARSCREEN)
      CALL settextposition(1,1,curpos)
      CALL HELP(myrows)
C
631   IK=INKEY(int2(I))
      IF(IK.NE.13)GOTO 631
      GOTO 333
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Display dpectral information (with I)
C
640   DUMMY=SETTEXTCOLOR(nhelpc)
      dummy4= setbkcolor(nhelpb)
      CALL clearscreen($GCLEARSCREEN)
      CALL settextposition(1,1,curpos)
      CALL SPEINF(myrows)
      GOTO 631
C. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
C
C...Error in options
C
76    WRITE(*,'(2A1,$)')CHAR(7),CHAR(7)
      GOTO 33
C
37    RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE GLEOUT(fstart,fend,YMIN,YMAX)
c
c  The top routine for generating gle output, uses the following frequency 
C  limits:
C
C    FSP1.FSP2 - limits of the total spectrum
C  FSTART,FEND - limits for the plotted spectrum
C        F1,F2 - limits for a given strip
c
c  Strip length is defined by PLOTL (in mm)
c  Paper size is defined in the 'size 29.5 21' line in WRIGLE (in cm)
c
      USE DFLIB
c
      implicit real*8 (a-h,o-z)
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (plotl=273.)
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1)
c
      INTEGER*4 ISPEC(maxpts),ISMALL,ILARGE,NPTS
      REAL*8 FREQS(maxpts)
      CHARACTER filnam*50,filgen*50,filout*50
c
      COMMON /SPEC/ISPEC,NPTS,ISMALL,ILARGE
      COMMON /FRE/FREQS
      COMMON /FNAM/FILNAM
c
      if(nstr.eq.0)nstr=1
      miny=YMIN
      maxy=YMAX
c
c...determine generic file name - fnam.ext type filename in the current
c   directory
c
      filgen=filnam
      do 14 nc=1,len_trim(filnam)
        if(filgen(nc:nc).eq.' '.or.filgen(nc:nc).eq.'.')goto 15
14    continue
15    nc=nc-1
c
c...OPTIONS
c
      if(RM.eq.0.d0)RM=1.d0
      FSP1=freqs(1)
      FSP2=freqs(NPTS)
      if(FSCAL.eq.0.0d0)FSCAL=(fend-fstart)/PLOTL
c
c
c...SCREEN REFRESH from here after every menu operation
c
59    call clearscreen($GCLEARSCREEN)
      WRITE(*,56)
56    FORMAT(1x/'_____g l e   O U T P U T',56(1H_)
     * ///22x,'min',9x,'max',10x,'range',3x,'10*mark',5x,'mm')
      WRITE(*,55)' full SPECTRUM:',FSP1,FSP2,FSP2-FSP1,
     * int((FSP2-FSP1)/(10.d0*rm))
55    FORMAT(a,1x,3f12.2,i7/)
c
c...parameters for individual strips
c
      RANGE=FSCAL*plotl
      F1=FSTART
      n=1
60    F2=f1+range
      if(fscal.ne.0.0d0)then
        rleng=range/fscal
        if(F2.gt.fend)rleng=(fend-f1)/fscal
        if(F1.lt.fstart)rleng=(f2-fstart)/fscal
      endif
      WRITE(*,61)'      STRIP:',n,F1,F2,range,int(range/(10.d0*rm)),
     *      rleng
61    Format(a,i2,2x,3f12.2,i7,f10.1)
      if(f2.lt.fend)then
        n=n+1
        f1=f1+range
        goto 60
      endif
c
58    permar=rm/fscal
      WRITE(*,57)nstr,rm,permar,fscal,miny,maxy,fstart,fend
57    FORMAT(1x/
     * '      1: Strips per page =',i7/
     * '      2:  Marker spacing =',f11.3,'          [',f8.2,' mm]'/
     * '      3:    Plot scaling =',f11.3,' units/mm'/
     * '      4:        Y-limits =',2I7/
     * '      5: Start frequency =',F11.3/
     * '      6: End   frequency =',F11.3//
     * '      Select 1-6 (ENTER=OK, -ve=exit) ..... ',$)
C
      READ(*,'(I2)',err=59)I
      if(i.lt.0)return
      if(i.lt.0.or.i.gt.6)goto 59
c
      if(i.eq.1)then
        write(*,'(1x/'' Number of strips per page (1,2,or 3) =  '',$)')
        read(*,'(i2)',err=59)n
        if(n.lt.1.or.n.gt.3)goto 59
        nstr=n
        goto 59
      endif
c
      if(i.eq.2)then
        write(*,'(1x/''  New marker spacing:  '',$)')
        read(*,*,err=59)temp
        if(temp.lt.0.001.or.temp.gt.1000.d0)goto 59
        rm=temp
        goto 59
      endif
c
      if(i.eq.3)then
        write(*,'(1x/''  New plot scaling:  '',$)')
        read(*,*,err=59)temp
        if(temp.le.0.001d0)goto 59
        if(temp.gt.1000.d0)goto 59
        fscal=temp
        goto 59
      endif
c
      if(i.eq.4)then
        write(*,70)ismall,ilarge
70      format(1x/' Y-axis limits of data: ',2i7//
     1            ' Specify new MINY,MAXY: ',$)
        read(*,'(2i15)',err=59)ia,ib
        if(ib.le.ia)goto 59
        if(ib.le.ismall.and.ia.le.ismall)goto 59
        if(ib.ge.ilarge.and.ia.ge.ilarge)goto 59
        miny=ia
        maxy=ib
        goto 59
      endif
c
      if(i.eq.5)then
        write(*,'(1x/'' New start frequency =  '',$)')
        read(*,*,err=59)temp
        if(temp.ge.fend)goto 59
        if(temp.lt.fsp1-plotl*fscal)goto 59
        fstart=temp
        goto 59
      endif
c
      if(i.eq.6)then
        write(*,'(1x/''   New end frequency =  '',$)')
        read(*,*,err=59)temp
        if(temp.le.fstart)goto 59
        if(temp.lt.fsp1-plotl*fscal)goto 59
        fend=temp
        goto 59
      endif
c
c...write a single .DAT file for the whole plotted spectrum
c
      filout=filgen(1:nc)//'.dat'
      write(*,'(1x//5x,''         Data written to '',$)')
      dummy=settextcolor(12)
      write(*,'(a)')filout(1:len_trim(filout))
      dummy=settextcolor(ntextc)
      OPEN(3,file=filout,status='unknown')
      write(3,1)'!  Spectrum from file:  '//filnam(1:len_trim(filnam))
      write(3,1)'!'
1     format(a)
      scale=maxy-miny
      do 100 n=1,npts
        if(freqs(n).lt.fstart)goto 100
        if(freqs(n).gt.fend)goto 102
        write(3,101)freqs(n),(ispec(n)-miny)/scale        
100   continue
101   format(f12.4,f9.4)
102   close(3)
c
c...generate the necessary .GLE files
c
      RANGE=FSCAL*plotl
      F1=FSTART
      n=1
65    F2=f1+range
      call wrigle(f1,f2,rm,n,nstr,filgen,nc)
      if(f2.lt.fend)then
        n=n+1
        f1=f1+range
        goto 65
      endif
c
      WRITE(*,'(1x//25x,
     *   ''f i n i s h e d,   Press ENTER to continue'')')     
200   ik=inkey(int2(n))
      if(ik.ne.13)goto 200
c
52    RETURN
      END
C
C_____________________________________________________________________________
C
      subroutine wrigle(f1,f2,rm,n,nstr,fnam,nc)
C
C     Write/append a spectral strip to a .GLE file
C
C     F1,F2 - frequency limits for the current gle graph
C        RM - marker spacing
C         n - the number of spectral strip
C      nstr - the number of spectral strips per page
C      fnam - generic file name
C        nc - number of characters to be used from FNAM
C
      USE DFLIB
C
      implicit real*8 (a-h,o-z)
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (plotl=273.)
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1)
c
      INTEGER*4 ISPEC(maxpts),ISMALL,ILARGE,NPTS
      REAL*8 FREQS(maxpts)
      CHARACTER fnam*50,filout*50,filnam*50,outstr*30,filgle*50
c
      COMMON /SPEC/ISPEC,NPTS,ISMALL,ILARGE
      COMMON /FRE/FREQS
      COMMON /FNAM/FILNAM
c
      maxlab=5
      topstr=0
      nn=(n-1)/nstr+1
      if(n-((n-1)/nstr)*nstr.eq.1)topstr=1
      xs=-5.45
      xtxt=0.3
c
C...single strip
c
      if(nstr.eq.1)then
        ys= 2.0
        sizey=20.
        ytxt=19.5
      endif
C
C...two strips
C
      if(nstr.eq.2)then
        sizey=11.
        if(topstr.eq.1)then
          ys=11.0
        else
          ys= 1.8
        endif
        ytxt=20.9
      endif
c
c...three strips
c
      if(nstr.eq.3)then
        sizey=7.4
        ytxt=21.2
        if(topstr.eq.1)then
          ys=14.6
        else
          nnn=n-(n/nstr)*nstr
          if(nnn.ne.0)then
            ys=8.2
          else
            ys=1.8
          endif
        endif
      endif
c
c...write .GLE file(s)
c
      write(outstr,'(I2)')nn
      if(nn.lt.10)then
        filout=fnam(1:nc)//outstr(2:2)//'.gle'
      else
        filout=fnam(1:nc)//outstr(1:2)//'.gle'
      endif
      if(nstr.eq.1.or.topstr.eq.1)then
        write(*,'(5x,'' Control file written to '',$)')
        dummy=settextcolor(12)
        write(*,'(a)')filout(1:len_trim(filout))
        dummy=settextcolor(ntextc)
        OPEN(4,file=filout,status='unknown')
      else
        OPEN(4,file=filout,status='old',access='append')
      endif
c
      if(topstr.eq.1)then
        write(4,2)
        write(4,1)'!      Plot of spectrum from file:  '//
     *         filnam(1:len_trim(filnam))
        write(4,2)
2       format('!',75(1h-))
        write(4,1)'!'
        write(4,1)'size 29.5 21'
1       FORMAT(a)
        write(4,1)' '
        write(4,1)'set lwidth 0.025'
        write(4,1)'set join round'
      endif
c
      write(4,1)' '
      write(outstr,'(a,2f6.2)')'amove',xs,ys
      write(4,1)outstr
      write(4,1)'begin graph'
      write(4,1)'    nobox'
      write(outstr,'(a,f6.2)')'    size 38.57',sizey
      write(4,1)outstr
      filout=fnam(1:nc)//'.dat'
      write(4,1)'    d1 bigfile '//filout
      write(4,'(a,f10.2,a,F10.2,a,F9.2,a,F9.3)')
     * '    xaxis  min ',F1,' max ',F2,' dticks ',10.d0*RM,
     *  ' dsubticks ',RM
      write(4,1)'    x2ticks off'
      write(4,1)'    xticks length 0.3'
      write(4,1)'    xsubticks length 0.12'
      write(4,1)'    xlabels hei 0.5 font texcmr'
c
      write(4,1)'    yaxis min  0.0 max 1.0'
      write(4,1)'    ylabels off'
      write(4,1)'    yticks off'
      write(4,1)'    d1 lstyle 1 smooth'
c
c...deal with more than MAXLAB marker labels
c
      tenm=rm*10.d0
      ftenm=dint(f1/tenm)*tenm
      if(ftenm.le.f1)ftenm=ftenm+tenm
      firstm=ftenm
c
      if(dint((f2-f1)/tenm).gt.real(maxlab))then
        mult=1
30      mult=mult+1
        if((f2-f1)/(mult*tenm).gt.maxlab)goto 30
c
31      flastm=ftenm+6.d0*tenm
        call xlab(firstm,f2,ftenm,flastm,tenm,mult)
        if(flastm.lt.f2-tenm)then
          ftenm=flastm+tenm
          goto 31
        endif
      endif
c
      goto 26
c
26    write(4,1)'end graph'
c
c...legend line
c
c     if(n.eq.(n/nstr)*nstr.or.n.eq.1)then
      if(topstr.eq.1)then
        write(4,1)' '
        write(4,1)'set font texcmr'
        write(4,1)'set hei 0.7'
        write(outstr,'(2f6.1)')xtxt,ytxt
        do 10 nn=len_trim(filnam),1,-1
          if(filnam(nn:nn).eq.'\')goto 11
10      continue
11      if(nn.ne.1)nn=nn+1
        write(4,1)'amove'//outstr
        nfgle=0
        do 39 m=nn,len_trim(filnam)
          nfgle=nfgle+1
          filgle(nfgle:nfgle)=filnam(m:m)
          if(filnam(m:m).eq.'_')then
            nfgle=nfgle+1
            filgle(nfgle:nfgle+8)='{\tt-\rm}'
            nfgle=nfgle+8
          endif
39      continue
        write(4,1)'text '//filgle(1:nfgle)
        write(4,1)'!'
        write(4,2)
      endif
c
      close(4)
c
      return
      end
C
C_____________________________________________________________________________
C
      subroutine xlab(firstm,f2,frtenm,flastm,tenm,mult)
C
C    firstm - frequency of first annotated marker
C    f2 - upper frequency limit of plot
C    frtenm,flastm - frequency of first and last big markers for drawing and
C                    possible labeling
C    tenm - big marker spacing
C    mult - label spacing which is MULT*TENM
C
      implicit real*8 (a-h,o-z)
      character*127 marlin
C
C...the xplaces line
C
      ftenm=frtenm
      write(4,'(a)')'!'
      write(marlin(1:9),'(a)')' xplaces '
      marind=10
22    if(tenm.lt.0.01d0)
     *   write(marlin(marind:marind+8),'(f9.3)',err=25)ftenm
      if(tenm.lt.0.1d0.and.tenm.ge.0.01d0)
     *   write(marlin(marind:marind+8),'(f9.2)',err=25)ftenm
      if(tenm.lt.1.d0 .and.tenm.ge.0.1d0)
     *   write(marlin(marind:marind+8),'(f9.1)',err=25)ftenm
      if(tenm.ge.1.d0)
     *   write(marlin(marind:marind+8),'(i9)',err=25)nint(ftenm)
      marind=marind+9
      if(marlin(marind-9:marind-9).ne.' ')then
        if(marind.le.127)marlin(marind:marind)=' '
        marind=marind+1
      endif
      ftenm=ftenm+tenm
      if(ftenm.le.flastm+1.d-6.and.ftenm.lt.f2)then
        goto 22
      else
        write(4,'(a)')marlin(1:marind-1)
      endif
c
c...the xnames line
c
      write(marlin(1:8),'(a)')' xnames '
      marind=9
      ftenm=frtenm
      marmul=nint(mult*tenm*1000.d0)
c
30    if(nint( dint(1000.d0*(ftenm-firstm)/marmul)*marmul) .ne.
     *   nint(      1000.d0*(ftenm-firstm)) )then
        write(marlin(marind:marind+8),'(a)')'   " "   '
        marind=marind+9
      else
23      if(tenm.lt.0.01d0)
     *     write(marlin(marind:marind+10),'(a,f9.3,a)',err=25)
     *     '"',ftenm,'"'
        if(tenm.lt.0.1d0.and.tenm.ge.0.01d0)
     *     write(marlin(marind:marind+10),'(a,f9.2,a)',err=25)
     *     '"',ftenm,'"'
        if(tenm.lt.1.d0 .and.tenm.ge.0.1d0)
     *     write(marlin(marind:marind+10),'(a,f9.1,a)',err=25)
     *     '"',ftenm,'"'
        if(tenm.ge.1.d0)
     *     write(marlin(marind:marind+10),'(a,i9,a)',err=25)
     *     '"',nint(ftenm),'"'
        marind=marind+11
      endif
c
      ftenm=ftenm+tenm
      if(ftenm.le.flastm+1.d-6.and.ftenm.lt.f2)then
        goto 30
      else
        write(4,'(a)')marlin(1:marind-1)
        write(4,'(a)')'!'
      endif
c
      return
c
25    write(4,27)
27    format('!'/'! SORRY - Could not generate xnames/xplaces lines'/
     * '!')
      return
      end
C
C_____________________________________________________________________________
C
      subroutine marsca(f1,f2)
c
c   Plot and label the marker scale for frequency limits F1,F2
c
      USE DFLIB
c
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
c
      LOGICAL*2 true
      PARAMETER (TRUE=.TRUE.)
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1)
c
      INTEGER*2 maxx,maxy,linofs,mymode,myrows,mycols,dummy,nbufer,nm
      INTEGER*4 dummy4
      CHARACTER*80 toplin,emplin,paslin,marlin,botlin
      CHARACTER BUFREQ*8
      REAL*8 FSTEP,F1,F2,RM,FRMARK,FLONG,H,YY
      REAL*8 RSMALL,RLARGE,RRSMAL,YYSTEP,YSHIFT
      COMMON /limits/wxy,maxx,maxy,linofs,curpos,ixy,
     * mymode,myrows,mycols
      COMMON /lines/toplin,emplin,paslin,botlin
      COMMON /plotda/RSMALL,RLARGE,RRSMAL,YYSTEP,YSHIFT
c
C...determine markers: RM=marker spacing,
C                      FRMARK=frequency of first marker
      FSTEP=F2-F1
      RM=100000.D0
1111  NM=FSTEP/RM
      IF(NM.LT.15)THEN
        RM=RM*0.1D0
        GOTO 1111
      ENDIF
      FRMARK=DINT(F1/RM)*RM
      IF(FRMARK.LT.F1)FRMARK=FRMARK+RM
C
C...plot the marker scale; NOTE that the X-axis of the floating point window
C   is set to frequencies
C
      marlin=emplin
      FSTEP=(F2-F1)/maxx
      flong=0.0d0
c
1114  YY=RSMALL-5.D0*YYSTEP
      H=DNINT(FRMARK/RM)
      IF(DNINT(10.D0*DINT(H*0.1D0)).EQ.H)THEN
        YY=RSMALL-13.D0*YYSTEP
        IF(FLONG.EQ.0.D0)FLONG=FRMARK
        NBUFER=(FRMARK-F1)/(F2-F1) * 80.D0
        IF(NBUFER-3.GE.1.AND.NBUFER+4.LE.79)THEN
          if(FRMARK.lt.1000000.)then
            WRITE(BUFREQ,'(F8.1)')FRMARK
          else
            WRITE(BUFREQ,'(F8.0)')FRMARK
          endif
          IF(NBUFER-3.LE.4)THEN
            marlin(NBUFER-3:NBUFER+4)=BUFREQ
            GOTO 1000
          ENDIF
          IF(marlin(NBUFER-6:NBUFER-6).EQ.' ')THEN
            marlin(NBUFER-3:NBUFER+4)=BUFREQ
          ENDIF
        ENDIF
      ENDIF
C
1000  DUMMY=SETCOLOR(nplotc)
      CALL moveto_w(FRMARK,YSHIFT,wxy)
      dummy=lineto_w(FRMARK,YY)
      FRMARK=FRMARK+RM
      IF(FRMARK.LE.F2)GOTO 1114
c
c...write the marker labels
c
      DUMMY=SETTEXTCOLOR(    1 )
      dummy4=setbkcolor (ntextb)
      CALL settextposition(int2(myrows-1),1,curpos)
      CALL outtext(marlin)
c
      return
      end
C
C_____________________________________________________________________________
C
      SUBROUTINE HELP(myrows)
C
      INTEGER*2 myrows,inkey,ik,I
C
      WRITE(*,632)
632   FORMAT(1x/'_____A V A I L A B L E   O P T I O N S',42(1h_)//
     * 9X,'A,S - shift screen window over the spectrum'/
     * 9X,'Q,E - zoom out/in in frequency'/
     * 9X,'W,Z - increase, decrease vertical scale'/
     * 9X,'2,3 - shift spectrum up/down'/
     * 9X,'K,L - move cursor over the spectrum'//
     * 9X,'      All of the above are fast/slow for ',
     *    'upper/lower case'//
     * 9X,'  , - center/quarter cursor'/
     * ' <HOME><END> - move to beginning/end of spectrum'/
     * 9X,'-/P - invert Y-axis / show spectral data points'/
     * 9X,'F/^ - manual frequency limits / toggle window height'/)
c
      if(myrows.eq.17)then
        write(*,'(15x,''Press ENTER '',$)')
631     IK=INKEY(I)
        IF(IK.NE.13)GOTO 631
        write(*,'(1x/)')
      endif
c
      WRITE(*,633)
633   FORMAT(
     * 9X,'  B - baseline subtraction'/
     * 9X,'  N - smoothing'/
     * 9X,'M/I - save current spectrum / display spectral information'/
     * 9X,'R/& - restore original spectrum / append spectrum'/
     * 9X,'  G - gle output'//
     * 9X,'  O - peak frequency of line under the cursor'/
     * 9x,'  0 - set fitting width, -ve value runs PEAKFINDER'/
     * 9x,'  9 - use cursor position for peak frequency/baseline level'/
     * 9x,'  = - average of last two measured frequencies'//
     * 7X,'ENTER - exits this help screen / exits SVIEW',$)
C
      RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE SPEINF(myrows)
C
C   Routine to write out information on the spectrum contained in the spectral
C   header
C
      USE DFLIB
C
      IMPLICIT INTEGER*2 (I-N)
      IMPLICIT REAL*4 (A-H,O-Z)
      INTEGER*4 MAXPTS
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1, 
     *           ncomc=15, ncomb=1)
      RECORD /rccoord/curpos
C
      COMMON /FLIMIT/FSTART,FEND,FINCR
      COMMON   /SPEC/ISPEC(MAXPTS),NPTS,ISMALL,ILARGE
      COMMON  /INFOC/COMENT,SAMPLE,LAMP,SCANSP
      COMMON   /INFO/IDAY,IMON,IYEAR,IHOUR,IMIN,ISEC,
     1               VKMST,VKMEND,GRID,SAMPRE,GAIN,TIMEC,PHASE,
     1               PPS,FRMOD,FRAMPL
      COMMON /lines/toplin,emplin,paslin,botlin
c
      REAL*8 FSTART,FEND,FINCR
      INTEGER*4 ISPEC,NPTS,ISMALL,ILARGE
      CHARACTER*80 toplin,emplin,paslin,botlin
      CHARACTER*72 COMENT
      CHARACTER*6 LAMP,SCANSP
      CHARACTER*20 SAMPLE
C
      write(*,'(60x,''IF__   N3__    __NK''/
     *          60x,''    |      |  |'')')
c                       352.00 10,13
      DUMMY=SETTEXTCOLOR(ncomc)
      dummy4= setbkcolor(ncomb)
      call settextposition(3,3,curpos)
      call outtext(emplin(1:76))
      if(coment.eq.'')coment='           '
      WRITE(toplin,502)COMENT
502   format(2x,A72,2(1H ))
      call settextposition(4,3,curpos)
      call outtext(toplin(1:76))
      call settextposition(5,3,curpos)
      call outtext(emplin(1:76))
      DUMMY=SETTEXTCOLOR(ntextc)
      dummy4= setbkcolor(ntextb)
      WRITE(*,'(1x//
     1             ''           Time and Date:  '',I2,'':'',I2,'':'',
     1 I2,'', '',I2,''/'',I2,''/'',I4)')IHOUR,IMIN,ISEC,
     1 IDAY,IMON,IYEAR
      WRITE(*,'(1X/''                    Lamp:  '',A)')LAMP
      WRITE(*,'(   ''          Vkm limits /mV:  '',F8.2,''-'',
     1 F8.2,A4)')VKMST,VKMEND
      WRITE(*,'(   ''                 Grid /V:  '',F6.1)')GRID
      WRITE(*,'(1X/''                  Sample:  '',A)')SAMPLE
      WRITE(*,'(   ''  Sample pressure /mTorr:  '',F6.1)')SAMPRE
C
      if(myrows.eq.17)then
        write(*,'(1x/27x,''Press ENTER ''/1x,$)')
631     IK=INKEY(I)
        IF(IK.NE.13)GOTO 631
        write(*,'(1x/)')
      endif
C
      if(gain.lt.0.099d0)then
        WRITE(*,'(1X/''                Gain /mV:  '',F6.1)')1000.*GAIN
      else
        WRITE(*,'(1X/''                Gain /mV:  '',F6.1)')GAIN
      endif
      WRITE(*,'(   ''        Time constant /s:  '',F6.3)')TIMEC
      WRITE(*,'(   ''              Phase /deg:  '',F6.1)')PHASE
      WRITE(*,'(   ''   N.delay, N.aver@point:   '',A)')SCANSP
      WRITE(*,'(   ''       Points per second:  '',F7.2)')PPS
      WRITE(*,'(1X/''   Modulation freq. /kHz:  '',F8.3)')FRMOD
      WRITE(*,'(   ''          deviation /kHz:  '',F6.1)')FRAMPL
      WRITE(*,'(1X/1X,I7,'' points, ranging from '',
     1 I10,''  to'',I10)')NPTS,ISMALL,ILARGE
C
      if(FSTART.eq.FEND)RETURN
      WRITE(*,'(15x,''frequency from'',F11.2,''  to'',F10.2,
     1 '', step size'',F8.5/)')FSTART,FEND,FINCR
      WRITE(*,'(/27x,''Press ENTER to continue''\)')
C
      RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE AUTOPK(NFIRST,NLAST,IYCUT,IBASE,NFIT,YMAX)
C
C   Routine to find all peaks in the currently viewed segment of the spectrum.
C   The coefficient of spectral expansion (NMULT) is not considered here, unlike
C   in the manual line measurement.
C   
C   NSTART,NEND - point limits in the spectrum to be considered by AUTOPK
C         IYCUT - intensity level below which lines are not to be considered
C         IBASE - intensity level of basline
C          NFIT - the number of points tobe used for fitting line contour
C          YMAX - Y-axis range of current display, used for scaling sticks
C

      USE DFLIB
C
      IMPLICIT REAL*8 (A-H,O-Z)
      INTEGER*2 IYCUT,IBASE,NFIT,inkey
      INTEGER*4 MAXPTS
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (maxlin=5000,maxpk=500)
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1)
C
      INTEGER*4 ISPEC(MAXPTS),ISMALL,ILARGE,NPTS
      REAL*8 FREQS(MAXPTS)
      CHARACTER FILNAM*50,outstr*21,stat*7,filout*60,filgen*50
C
      COMMON /FRE/FREQS
      COMMON /SPEC/ISPEC,NPTS,ISMALL,ILARGE
      COMMON /FRFIT/XFIT(maxpk),YFIT(maxpk)
      COMMON /FNAM/FILNAM
C
c...preliminaries
c
      do 14 nc=len_trim(filnam),1,-1
        if(filnam(nc:nc).eq.'\')goto 15
14    continue
15    if(nc.eq.0.or.nc.eq.1)then
        filgen=''
      else
        filgen=filnam(1:nc)
      endif
c
961   CALL clearscreen($GCLEARSCREEN)
      dummy=displaycursor($gcursoron)
      WRITE(*,910)
910   FORMAT(1X/'_____P E A K F I N D E R',56(1h_)//)
      WRITE(*,912)IYCUT,IBASE
912   FORMAT(5x,'Peaks will be identified for lines with intensity ',
     * 'above'/5x,'the cutoff value and peak intensities will be '
     * 'relative'/5x,'to the specified baseline'//
     *   5x,'Y-axis cutoff:   ',I6/
     *   5x,'Y-axis baseline: ',I6/)
C
      write(*,960)
960   format(5x,'Select search range:  0 = current window'/
     *       5x,22x,                  '1 = complete spectrum'//
     *       5x,17x,             '.... ',$)
      read(*,'(I5)',err=961)iserch
      if(iserch.lt.0.or.iserch.gt.1)goto 961
      if(iserch.eq.0)then
        NSTART=NFIRST
        NEND=NLAST
      else
        NSTART=1
        NEND=npts
      endif
      fstart=freqs(nstart)
      fend=freqs(fend)
C
      STAT='NEW'
927   WRITE(*,'(1X/5x,''OUTPUT FILE NAME :  '',$)')
      READ(*,'(a)',ERR=927)OUTSTR
      STAT='NEW'
918   filout=filgen(1:len_trim(filgen))//outstr(1:len_trim(outstr))
      OPEN(3,FILE=filout,STATUS=STAT,ERR=917)
      GOTO 920
C
917   WRITE(*,'(1X/5x,
     *  ''THIS FILE ALREADY EXISTS, OVERWRITE (Y/N)?  '',$)')
      READ(*,'(a)',ERR=917)CHARFL
      IF(CHARFL.EQ.'Y'.OR.CHARFL.EQ.'y')THEN
        STAT='UNKNOWN'
        GOTO 918
      ENDIF
      IF(CHARFL.EQ.'N'.OR.CHARFL.EQ.'n')THEN
919     WRITE(*,'(5x,''New file name:  '',$)')
        READ(*,'(a)',ERR=919)outstr
        GOTO 918
      ENDIF
C
C...output header
C
920   write(3,926)filnam(1:len_trim(filnam)),IYCUT,NFIT,IBASE
926   format(78(1H-)/
     * ' SVIEW PeakFinder RESULTS FOR SPECTRUM:'/
     *  19x,a//'   cutoff: ',I8,20X,'fitting width:',I5/
     *        ' baseline: ',I8/78(1H-)/)
      WRITE(3,950)
950   FORMAT('    Frequency     Error   Intensity     FWHH'/)
C
C
C...establish maxima greater than IYCUT on the basis of five peaked points
C   and fit their position, two iterations of the fit are carried out to
C   compensate for the inaccuracy in the initial central point
C
      IX=NFIT/4
      I2X=2*IX
      I=NSTART+NFIT
      nplu=0
      fsum=0.0d0
      fsumsq=0.d0
      WRITE(*,938)
938   FORMAT(1x//5x,'The number of identified lines: '/'     ',$)
C
C
C...Main loop over the spectrum
C
1514  I=I+1
      IF(I.GT.(NEND-NFIT))GOTO 1515
      IF(ISPEC(I).LT.IYCUT)GOTO 1514
      IF(ISPEC(I).GT.ISPEC(I-I2X).AND.ISPEC(I).GT.ISPEC(I-IX).AND.
     *   ISPEC(I).GT.ISPEC(I+I2X).AND.ISPEC(I).GT.ISPEC(I+IX))THEN
c
C...determine peak frequency in NTIMES iterations
C
        NTIMES=0
        ist=i
922     J=0
        DO 921 II=-NFIT/2,NFIT/2,1
          J=J+1
          K=IST+II
          XFIT(J)=FREQS(K)
          YFIT(J)=ISPEC(K)
921     CONTINUE
C
        CALL PEAKF(NFIT,XPEAK,ERRORX,YPEAK,A0,A1)                       <--- PEAKF
        NTIMES=NTIMES+1
        if(ntimes.le.2)then
          ist=1+nint(real(npts-1)*(xpeak-freqs(1))/
     *                                 (freqs(npts)-freqs(1)))
          if(ist.lt.i2x)ist=i2x
          if(ist.gt.npts-i2x)ist=npts-i2x
          goto 922
        endif
c        
        nplu=nplu+1
c
c..halfwidth
c
        ist=1+nint(real(npts-1)*(xpeak-freqs(1))/
     *                                 (freqs(npts)-freqs(1)))
        if(ist.lt.i2x)ist=i2x
        if(ist.gt.npts-i2x)ist=npts-i2x
        rtemp=0.5d0*(ypeak+ibase)
        if(ist.gt.npts)ist=npts
        do 817 nn=ist,nstart+1,-1
          if((ispec(nn)-rtemp)*(ispec(nn-1)-rtemp).gt.0.d0)goto 817
          hwl=freqs(nn-1)+(rtemp-ispec(nn-1))*
     *              (freqs(nn)-freqs(nn-1))/real(ispec(nn)-ispec(nn-1))
          goto 818
817     continue
818     do 819 nn=ist,nend-1
          if((ispec(nn)-rtemp)*(ispec(nn+1)-rtemp).gt.0.d0)goto 819
          hwu=freqs(nn)+(rtemp-ispec(nn))*
     *              (freqs(nn+1)-freqs(nn))/real(ispec(nn+1)-ispec(nn))
          goto 814
819     continue
814     fwhh=hwu-hwl       
        fsum=fsum+fwhh
        fsumsq=fsumsq+fwhh*fwhh
c
        linint=ypeak-ibase
        ndash=nint(abs(32.0*REAL(linint)/ymax))
        if(ndash.gt.32)ndash=32
        if(ndash.lt.1)then
          write(3,947)xpeak,errorx,linint,fwhh,'.'
        else
          write(3,947)xpeak,errorx,linint,fwhh,('-',LLLL=1,ndash)
        endif
947     FORMAT(F14.5,' +-',F8.5,I8,F11.5,'  |',32a1)

c         DO 3036 N=1,20
c           WRITE(NOUT,3037)NCC(N),N*0.05,('*',LLLL=1,NCC(N))
c3036     CONTINUE
c3037     FORMAT(1X,I2,' <',F4.2,1X,67A1)

c
        IF(NPLU.EQ.10*(NPLU/10))WRITE(*,'(I5,$)')NPLU
        I=I+I2X
      endif
      GOTO 1514
C
C...conclusion
C
1515  fwhhm=fsum/nplu
      if(nplu.gt.0)then
        fwhhd=dsqrt(fsumsq/real(nplu)-fwhhm*fwhhm)
      else
        fwhhd=0.d0
      endif
      WRITE(3,962)fwhhm,fwhhd,nplu
962   FORMAT(1x/'                        Mean FWHH =',F9.5,' +-',F9.5/
     *          ' Total number of identified lines =',I9/)
      WRITE(3,'(78(1H-))')
      close(3)
c
      WRITE(*,
     * '(1X//5x,''PEAKFINDER found'',i7,'' transitions''//
     *       5x,''Output has been written to '',$)')nplu      
      dummy=settextcolor(12)
      write(*,'(a)')filout(1:len_trim(filout))
      dummy=settextcolor(ntextc)
c
      WRITE(*,'(1x/40x,''Press ENTER to continue  '',$)')
      n=0
200   ik=inkey(int2(n))
      if(ik.ne.13)goto 200
C
941   RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE PEAKF(N,XPEAK,ERRORX,YPEAK,A0,A1)
C
C   Position of line maximum is established using a linear transformation
C   of the parabola
C                          2          Y-Yo
C   from  Y = a + b X + c X   to      ---- = b + c ( X - Xo)
C                                     X-Xo
C
C   The central XY point is used for Xo,Yo and a straight line fit gives
C   b and c.  Peak of the parabola is at -b/2c.  This routine will locate both
C   upward and downward peaks (c -ve and +ve), with reliability increasing
C   with the proximity of the central point in the data to the peak
C
C      N - number of XY data pairs (odd)
C    X,Y - arrays containg XY coordinates of spectral points
C  XPEAK - on exit the required central fitted peak position
C ERRORX - on exit the error on the fitted peak position
C     A0 - parameter b of the reduced parabola
C     A1 - parameter c of the reduced parabola
C
      IMPLICIT REAL*8 (A-H,O-Z)
      INTEGER*2 N
      parameter (maxpk=500)
c
      COMMON /FRFIT/X(maxpk),Y(maxpk)
C
C...value of X is given a small fractional shift so that no two points
C   have the same frequency
      NCENT=N/2+1
      DO 1 I=1,N
        IF(I.EQ.NCENT)GOTO 1
        X(I)=X(I)-X(NCENT)+I*1.D-7
        Y(I)=(Y(I)-Y(NCENT))/X(I)
1     CONTINUE
C
C...The number of points in the fit is N-1 since the central point is
C   used for biasing
C
      SUMX=0.D0
      SUMY=0.D0
      SUMXY=0.D0
      SUMX2=0.D0
      SUMY2=0.D0
      DO 2 I=1,N
        IF(I.EQ.NCENT)GOTO 2
        SUMX=SUMX+X(I)
        SUMY=SUMY+Y(I)
        SUMXY=SUMXY+X(I)*Y(I)
        SUMX2=SUMX2+X(I)*X(I)
        SUMY2=SUMY2+Y(I)*Y(I)
2     CONTINUE
C
C...coefficients
      RN=N-1
      CXX=SUMX2-SUMX*SUMX/RN
      CXY=SUMXY-SUMX*SUMY/RN
      A1=CXY/CXX
      IF(A1.EQ.0.D0)THEN
        ERRORX=0.D0
        XPEAK=0.D0
        RETURN
      ENDIF
      A0=(SUMY-A1*SUMX)/RN
      XPEAK=X(NCENT)-0.5D0*A0/A1
      YPEAK=Y(NCENT)+(XPEAK-X(NCENT))*(A0+A1*(XPEAK-X(NCENT)))
C
C...error
      CYY=SUMY2-SUMY*SUMY/RN
      ERA1S=((CYY/CXX)-(CXY/CXX)**2)/(RN-2.D0)
      ERA0S=SUMX2*ERA1S/RN
      rtemp=ERA1S/A1**2+ERA0S/A0**2
      if(rtemp.le.0.0d-40)then
        errorx=0.0d0
      else        
        ERRORX=ABS(0.5D0*(A0/A1))*DSQRT(ERA1S/A1**2+ERA0S/A0**2)
      endif
C
      RETURN
      END
C
C_____________________________________________________________________________
C
      subroutine smooth(icontr,iycutl,iycut,nspt)
C
C   Least squares smoothing routine:
C
C    ICONTR=1 - just smooth the data in IDATA
C    ICONTR=2 - subtract the baseline from the spectrum in IDATA,
C               either completely if no cutoff limits, or initialise
C               when cutoff limits wanted
C    ICONTR=3 - complete baseline subtraction with cutoff limits
C    iycutl,iycut - smoothing cutoff limits for baseline subtraction
C                   determined in the calling routine after the
C                   first call to SMOOTH
C
      PARAMETER (maxpts=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (maxsmo=500)
C
      integer*4 idata(maxpts),ioldat(maxpts),itemp(maxpts)
      integer*4 ismall,ilarge,npts,icutof(maxpts)
      real spol(maxsmo)
      COMMON /SPEC/Idata,NPTS,ISMALL,ILARGE
      common /bufers/ioldat,itemp,icutof
C
      if(icontr.eq.3)goto 1200
C
      if(icontr.eq.2)then
        WRITE(*,2)
2       format(1X/'_____B A S E L I N E   S U B T R A C T I O N',
     * 36(1h_)///
     * 5x,'The baseline is defined by smoothing the spectrum with'/
     * 5x,'an interval which is much longer than the linewidth'/
     * 7x,'(-ve number of smoothing points allows the use of Y-axis'/
     * 7x,' cutoff to attenuate the effect of strong lines)'//5x,
     *   '- Kisiel and Pszczolkowski, J.Mol.Spectrosc. 158,318(1993)'/)
      else
        WRITE(*,1)
1       format(1x,/
     * '_____L E A S T   S Q U A R E S   S M O O T H I N G',30(1h_)///
     * 5x,'This is standard cubic polynomial smoothing of',
     * ' Savitsky and Golay and'/5x,
     * 'it has been recommended not to use smoothing intervals longer'/
     *  5x,'than 0.7*FWHH'//5x,
     *   '- Savitsky and Golay, Analyt.Chem. 36,1627(1964)'/5x,
     *   '- Edwards and Wilson, Appl.Spectrosc. 28,541(1974)'/)
      endif
c
1101  if(icontr.eq.1)then
        WRITE(*,1102)
      else
        WRITE(*,1202)
      endif
1102  FORMAT(1X//5x,'Specify the number of points for ',
     * 'the smoothing interval '
     *  /5x,'( >3 and odd )'/30x,'  .... ',$)
1202  FORMAT(1X//5x,'Specify the number of points for ',
     * 'the smoothing interval '/5x,
     *  '( >3 and odd, -ve value for fine control with cutoff limits)'
     *  //30x,'  .... ',$)
      READ(*,'(i5)',ERR=1101)NSPT
      if(icontr.eq.2.and.nspt.lt.0)then
        nspt=iabs(nspt)
        icut=1
      else
        icut=0
      endif
      IF(NSPT.LE.3.OR.NSPT.GT.maxsmo)GOTO 1101
      IF((NSPT/2)*2.EQ.NSPT)GOTO 1101
C
      if(icontr.eq.2)then
        if(icut.eq.1)then
          iycutl=-1
          iycut=-1
          M=real(NSPT)*1.0
          MM=2*NSPT+1
          if(mm.gt.maxsmo)then
            M=maxsmo/2
            mm=2*m+1
          endif
          goto 1201
        endif
        WRITE(*,'(1X//5x,''S U B T R A C T I N G''//)')
      else
        WRITE(*,'(1X//5x,''S M O O T H I N G''//)')
      endif
c
C    For smoothing interval of length 2m+1 the elements of the smoothing
C    (cubic) polynomial are given by:
C
C           3(3m**2 + 3m -1 - 5s**2)
C   c(s) =  ------------------------
C           (2m+1) (2m-1) (2m+3)
C
C   where s runs from -m to +m (T.H.Edwards and P.D.Wilson, Applied
C                               Spectroscopy 28,541-545(1974))
C
C
C...set up coefficients in smoothing polynomial
C
1200  M=NSPT/2
      MM=NSPT
1201  T1=3.D0/((2*M+1)*(2.D0*M-1.D0)*(2*M+3))
      T2=3*M*M+3.D0*M-1.D0
      DO 1103 j=1,MM
        IS=j-M-1
        SPOL(j)=T1*(T2-5*IS*IS)
1103  CONTINUE
c
c...straightforward smoothing
c
      if(icontr.eq.1.or.(icontr.eq.2.and.icut.eq.1))then
        iround=0
        do 2105 j=1,npts
          itemp(j)=idata(j)
2105    continue
2545    DO 2543 I=1,npts
          SUM=0.
          DO 2544 J=1,MM
            IS=J-M-1
            II=I+IS
            IF(II.LT.1)II=iabs(II)+1
            IF(II.GT.npts)II=npts-(II-npts-1)
              SUM=SUM+itemp(II)*SPOL(J)
2544      CONTINUE
          if(icontr.eq.2.and.icut.eq.1)then
            icutof(i)=sum
          else
            Idata(I)=sum
          endif
2543    CONTINUE
c
        if(icontr.eq.2.and.icut.eq.1)then
          iround=iround+1
          if(iround.lt.5)then
            do 2546 j=1,npts
              itemp(j)=icutof(j)
2546        continue
            goto 2545
          endif
        endif
c
        write(*,'(2x,$)')
        return
      endif
C
C
C...Subtraction of background by multiple smoothing of interferogram with
C   least squares smoothing interval
C
C...Smooth the necessary number of times
      DO 1104 k=1,5
        if(icontr.ne.3)write(*,'(20x,'' Smooth  '',i1)')k
        do 1105 j=1,npts
          itemp(j)=idata(j)
          if(k.eq.1.and.icut.eq.1)then
            if(itemp(j).gt.icutof(j)+iycut)itemp(j)=icutof(j)+iycut
            if(itemp(j).lt.icutof(j)+iycutl)itemp(j)=icutof(j)+iycutl
          endif
1105    continue
        DO 543 I=1,npts
          SUM=0.
          DO 544 J=1,NSPT
            IS=J-M-1
            II=I+IS
            IF(II.LT.1)II=iabs(II)+1
            IF(II.GT.npts)II=npts-(II-npts-1)
            SUM=SUM+itemp(II)*SPOL(J)
544       CONTINUE
          Idata(I)=sum
543     CONTINUE
        DO 545 I=1,npts
          ITEMP(I)=IDATA(I)
545     CONTINUE
1104  continue
C
      do 1106 j=1,npts
        itemp(j)=idata(j)
        idata(j)=ioldat(j)-idata(j)
1106  continue
c
      return
      end
C
C_____________________________________________________________________________
C
      SUBROUTINE SAVESP
C
C   This routine saves the recorded data into a file in FREQLIN type binary
C   format which consists of header, INTEGER*2 intensities, and frequency
C   limits and increment.
C
C   File format byte by byte:
C
C   COMENT                    character*72
C   IDAY,IMON,IYEAR       3 * integer*2
C   IHOUR,IMIN,ISEC       3 * integer*2
C   LAMP                      character*6
C   VKMST,VKMEND          2 * real*4
C   GRID                      real*4
C   SAMPLE                    character*20
C   SAMPRE                    real*4
C   GAIN,TIMEC,PHASE      3 * real*4
C   SCANSP                    character*6      not used in FREQLIN standard
C   PPS                       real*4           =PPS+500 in FREQLIN standard           
C   FRMOD,FRAMPL          2 * real*4
C   then either:          
C     NPTS                    integer*2
C     ISMALL,ILARGE       2 * integer*2        these are I*4 internally
C   or                    
C     -1                      integer*2
C     NPTS                    integer*4
C   ISPEC              NPTS * integer*2        this is I*4 internally
C   FSTART,FEND,FINCR     3 * real*8           point f's determined by FSTART and FINCR
C   NCALPT                    integer*2        =0 ensuring backwards compatibility      
C                                                         
C                     
      USE DFLIB       
C                     
      IMPLICIT INTEGER*2 (I-N)
      IMPLICIT REAL*4 (A-H,O-Z)
      INTEGER*4 MAXPTS,N
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (ntextc=0, ntextb=7, nplotc=15, nplotb=1)
C
      COMMON /FLIMIT/FSTART,FEND,FINCR
      COMMON   /FNAM/FILOLD
      COMMON   /SPEC/ISPEC(MAXPTS),NPTS,ISMALL,ILARGE
      COMMON  /INFOC/COMENT,SAMPLE,LAMP,SCANSP
      COMMON   /INFO/IDAY,IMON,IYEAR,IHOUR,IMIN,ISEC,
     1               VKMST,VKMEND,GRID,SAMPRE,GAIN,TIMEC,PHASE,
     1               PPS,FRMOD,FRAMPL
c
      REAL*8 FSTART,FEND,FINCR
      INTEGER*4 ISPEC,NPTS,ISMALL,ILARGE,imean
      CHARACTER FILOLD*50,CHARFL,STAT*7,filgen*50,filnam*60,outstr*20
      CHARACTER*72 COMENT
      CHARACTER*6 LAMP,SCANSP
      CHARACTER*20 SAMPLE
C
C...preliminaries
C
      do 14 nc=len_trim(filold),1,-1
        if(filold(nc:nc).eq.'\')goto 15
14    continue
15    if(nc.eq.0.or.nc.eq.1)then
        filgen=''
      else
        filgen=filold(1:nc)
      endif
c
      WRITE(*,2)
2     format(1X/'_____O U T P U T   T O   F I L E',48(1h_)///)
51    write(*,50)filold
50    format(1x/'     This spectrum is from file:  ',a//
     *          '     Specify file name for output'/
     *          '     (without the path)            ....  ',$)
      read(*,'(a)',err=51)outstr
C
22    stat='NEW'
26    filnam=filgen(1:len_trim(filgen))//outstr(1:len_trim(outstr))
      OPEN(3,FILE=FILNAM,STATUS=STAT,FORM='BINARY',ERR=21)
      WRITE(3)COMENT,IDAY,IMON,IYEAR,IHOUR,IMIN,ISEC,
     1 LAMP,VKMST,VKMEND,GRID,SAMPLE,SAMPRE,GAIN,TIMEC,PHASE,
     1 SCANSP,PPS,FRMOD,FRAMPL
C
c...Intensities of spectral data points - centre intensity on zero
c
      ISMALL= 1000000000
      ILARGE=-1000000000
      do 100 n=1,npts
        if(ispec(n).lt.ismall)ismall=ispec(n)
        if(ispec(n).gt.ilarge)ilarge=ispec(n)
100   continue
      imean=(ilarge+ismall)/2
      if(ilarge-ismall.gt.60000)then
        scale=60000./real(ilarge-ismall)
      else
        scale=1.d0
      endif
c
      if(npts.le.32000)then
        WRITE(3)int2(NPTS),int2(scale*(ISMALL-imean)),
     *                     int2(scale*(ILARGE-imean))
      else
        WRITE(3)int2(-1),npts
      endif
      DO 20 N=1,NPTS
        WRITE(3)int2(scale*(ispec(n)-imean))
20    CONTINUE
      ncalpt=0
C
C...Frequency limits and increment
C
      WRITE(3)FSTART,FEND,FINCR,ncalpt
C
      CLOSE(3)
      write(*,'(1x//5x,''Output has been written to '',$)')
      dummy=settextcolor(12)
      write(*,'(a)')filnam(1:len_trim(filnam))
      dummy=settextcolor(ntextc)
      WRITE(*,'(1x/40x,''Press ENTER to continue  '',$)')
200   ik=inkey(ik)
      if(ik.ne.13)goto 200
      GOTO 23
c
21    WRITE(*,'(1X/''     THIS FILE ALREADY EXISTS, OVERWRITE (Y/N)?  ''
     * ,$)')
      READ(*,1300,ERR=21)CHARFL
      IF(CHARFL.EQ.'Y'.OR.CHARFL.EQ.'y')THEN
        STAT='UNKNOWN'
        GOTO 26
      ENDIF
      IF(CHARFL.EQ.'N'.OR.CHARFL.EQ.'n')THEN
27      WRITE(*,'('' New file name:  '',$)')
        READ(*,1300,ERR=27)outstr
1300    FORMAT(A)
        GOTO 22
      ENDIF
C
23    RETURN
      END
C
C_____________________________________________________________________________
C
      SUBROUTINE INTERP(FSTART,FEND,nstart,nend,nplot,nmult)
C
      PARAMETER (MAXPTS=  200000)
c     PARAMETER (MAXPTS= 3000000)
c     PARAMETER (MAXPTS= 6000000)
c     PARAMETER (MAXPTS=10000000)
      PARAMETER (intpt=1024)
C
C  Interpolation by successive doubling of the number of data points
C  (using Lagrange's formula for quadratic interpolation)
C
C    FSTART,FEND - bounding frequencies
C    NSTART,NEND - indices for points with FTSART,FEND in ISPEC
C          nplot - number of points to be plotted from the interpolation
C                  buffers ISPINT,FREINT
C          nmult - the multiplier by which the density of points has been
C                  increased
C
C
      implicit real*8 (a-h,o-z)
      INTEGER*4 ISPEC(maxpts),ISPINT(intpt)
      REAL*8 FREINT(intpt),work(intpt)
      COMMON /SPEC/ISPEC,NPTS,ISMALL,ILARGE
      common /intpol/freint,ispint
c
      i=0
      do 1 n=nstart,nend
        i=i+1
        work(i)=dble(ispec(n))
1     continue
      nplot=i
c
2     I=0
      DO 103 N=2,2*nplot-4,2
        i=i+1
        ispint(n-1)=work(i)
        ispint(n)=0.375d0*work(i)+0.75d0*work(i+1)-0.125d0*work(i+2)
103   CONTINUE
      ispint(2*nplot-3)=work(i+1)
      ispint(2*nplot-2)=
     *           -0.125d0*work(i)+0.75d0*work(i+1)+0.375d0*work(i+2)
      ispint(2*nplot-1)=work(i+2)
      nplot=2*nplot-1
      nmult=nmult*2
c
      if(2*nplot.le.intpt)then
        do 3 n=1,nplot
          work(n)=dble(ispint(n))
3       continue
        goto 2
      endif
c
      fincr=(fend-fstart)/(nplot-1)
      do 4 n=1,nplot
        freint(n)=fstart+(n-1)*fincr
4     continue
c
      RETURN
      END
c
C_____________________________________________________________________________
C
      subroutine sgame
c
      USE DFLIB
C
      RECORD /rccoord/curpos
      RECORD /xycoord/ixy
      RECORD /wxycoord/wxy
      parameter (nhorpt=800)
c
      INTEGER*2 maxx,maxy,linofs,mymode,myrows,mycols,dummy
      real*8 s(nhorpt)
c
      COMMON /limits/wxy,maxx,maxy,linofs,curpos,ixy,
     * mymode,myrows,mycols
c
      call setviewport(0,0,maxx,maxy)
c
c   Peak parameters (normalised, second derivative Lorentzians):
c
c      linewidth=1
c      frequency range= 0 to 50
c      intensity range= 0 to 100
c
      fmult=50./(maxx+1)
      do 2 n=1,maxx+1
        s(n)=0.
2     continue
c
      call seed(-1)
      do 200 nn=1,10
        call random(smult)
        smult=smult*100.
        call random(fzero)
        fzero=fzero*48.+1.
c
        do 1 n=1,maxx+1
          f=fmult*n-fzero
          x=f*f+1.
          s(n)=s(n)-(3.*x-4.)/(x**3)  *smult
1       continue
200   continue
c
      dummy=setcolor(15)
      slevel=maxy-40
      do 100 n=1,maxx+1
        iy=slevel-s(n)
        if(iy.ge.maxy)iy=maxy-1
        if(n.eq.1)then
          CALL MOVETO (INT2( 0), INT2(iy), ixy)
        else
          dummy=lineto(INT2( n-1), INT2(iy))
        endif
100   continue
c
      dummy=setcolor(1)
      dummy=floodfill(int2(maxx/2),int2(maxy),15)
c
      return
      end
C
C_____________________________________________________________________________
C
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
c   or hex E0 is returned and aniother call to GETCHARQQ is required to
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

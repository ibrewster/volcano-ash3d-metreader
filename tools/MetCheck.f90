!##############################################################################
!##############################################################################
      program MetCheck

      use MetReader

      implicit none

      integer             :: iargc, nargs
      integer             :: status,iostat,stat
      character (len=100) :: arg

      real(kind=4)        :: inlon,inlat

      character(len=100)  :: infile1
      integer             :: nxmax,nymax,nzmax !,nsize
      real(kind=4),dimension(:)    ,allocatable :: lon_grid
      real(kind=4),dimension(:)    ,allocatable :: lat_grid
      real(kind=4),dimension(:)    ,allocatable :: z_cc
      logical             :: IsPeriodic

      integer :: idf, igrid, iw, iwf, iwfiles
      integer :: ivar
      integer :: iy
      integer :: i,j,p,np,imetstep
      real(kind=4) :: v1,v2,tmp

      integer :: iprojflag
      real(kind=8) :: lambda0,phi0,phi1,phi2,k0,radius_earth
      logical :: IsLatLon

      integer :: BaseYear = 1900
      logical :: useLeap  = .true.
        ! min and max possible for this var (for error-checking)
      real(kind=4)    ,dimension(50,2) :: Met_var_MinMax
      integer,dimension(8) :: values
      integer :: Current_Year
      real(kind=8) :: hsince
      real(kind=8) :: HS_hours_since_baseyear  ! function that calculates hours
      integer      :: HS_YearOfEvent
      integer      :: HS_DayOfYear
      real(kind=8) :: HS_HourOfDay
      integer      :: idx

      Met_var_MinMax(1,1:2) = (/ -1000.0_4, 80000.0_4 /)  ! GPH
      Met_var_MinMax(2,1:2) = (/  -200.0_4,   200.0_4 /)  ! U
      Met_var_MinMax(3,1:2) = (/  -200.0_4,   200.0_4 /)  ! V
      Met_var_MinMax(4,1:2) = (/   -20.0_4,    20.0_4 /)  ! W
      Met_var_MinMax(5,1:2) = (/   130.0_4,   350.0_4 /)  ! T

      ! Make user MetReader is using the same calendar
      MR_BaseYear = BaseYear
      MR_useLeap  = useLeap

!     TEST READ COMMAND LINE ARGUMENTS
      nargs = iargc()
      if (nargs.lt.3) then
        write(MR_global_info,*)"ERROR: not enough command-line arguments."
        write(MR_global_info,*)"  Usage: MetCheck iwf idf filename [year]"
        write(MR_global_info,*)"   where "
        write(MR_global_info,*)"     iwf =  3 NARR3D NAM221 32 km North America files"
        write(MR_global_info,*)"     iwf =  4 NARR3D NAM221 32 km North America files"
        write(MR_global_info,*)"     iwf =  5 NAM216 AK 45km"
        write(MR_global_info,*)"     iwf =  6 NAM Regional 90 km grid 104"
        write(MR_global_info,*)"     iwf =  7 CONUS 212 40km"
        write(MR_global_info,*)"     iwf =  8 CONUS 218 (12km)"
        write(MR_global_info,*)"     iwf = 10 NAM 242 11.25 km AK"
        write(MR_global_info,*)"     iwf = 11 NAM 196 2.5 km HI"
        write(MR_global_info,*)"     iwf = 12 NAM 198 5.953 km AK"
        write(MR_global_info,*)"     iwf = 13 NAM 91 2.976 km AK"
        write(MR_global_info,*)"     iwf = 20 GFS 0.5"
        write(MR_global_info,*)"     iwf = 21 GFS 1.0"
        write(MR_global_info,*)"     iwf = 22 GFS 0.25"
        write(MR_global_info,*)"     iwf = 23 NCEP / DOE reanalysis 2.5 degree files"
        write(MR_global_info,*)"     iwf = 24 NASA-MERRA-2 reanalysis 0.625x0.5 degree files"
        write(MR_global_info,*)"     iwf = 25 NCEP/NCAR reanalysis 2.5 degree files"
        write(MR_global_info,*)"     iwf = 27 NOAA-CIRES reanalysis 2.5 degree files"
        write(MR_global_info,*)"     iwf = 28 ECMWF Interim Reanalysis (ERA-Interim)"
        write(MR_global_info,*)"     iwf = 32 Air Force Weather Agency subcenter = 0"
        write(MR_global_info,*)"     iwf = 33 CCSM3.0 Community Atmosphere Model (CAM)"
        write(MR_global_info,*)"     iwf = 40 NASA-GEOS Cp"
        write(MR_global_info,*)"     iwf = 41 NASA-GEOS Np"
        write(MR_global_info,*)"     iwf = 50 WRF"
        write(MR_global_info,*)"     "
        write(MR_global_info,*)"     idf = 2 NetCDF"
        write(MR_global_info,*)"     idf = 3 grib"
        write(MR_global_info,*)"     "
        write(MR_global_info,*)"     filename = name of file of root directory for NCEP"
        write(MR_global_info,*)"     "
        write(MR_global_info,*)"     [year] = year for NCEP tests"
        write(MR_global_info,*)"               This is optional and defaults to current year"
        write(MR_global_info,*)"               if not provided."

        stop 1
      else
        call get_command_argument(1, arg, status)
        read(arg,*)iwf
        if(iwf.ne.3.and.&
           iwf.ne.4.and.&
           iwf.ne.5.and.&
           iwf.ne.6.and.&
           iwf.ne.7.and.&
           iwf.ne.8.and.&
           iwf.ne.10.and.&
           iwf.ne.11.and.&
           iwf.ne.12.and.&
           iwf.ne.13.and.&
           iwf.ne.20.and.&
           iwf.ne.21.and.&
           iwf.ne.22.and.&
           iwf.ne.23.and.&
           iwf.ne.24.and.&
           iwf.ne.25.and.&
           iwf.ne.26.and.&
           iwf.ne.27.and.&
           iwf.ne.28.and.&
           iwf.ne.32.and.&
           iwf.ne.33.and.&
           iwf.ne.41.and.&
           iwf.ne.42)then
          write(MR_global_info,*)"ERROR: windformat not recognized"
          stop 1
        endif
        call get_command_argument(2, arg, status)
        read(arg,*)idf
        if(idf.ne.2.and.&
           idf.ne.3)then
          write(MR_global_info,*)"ERROR: Only netcdf (2) and grib (3) supported"
          stop 1
        endif

        call get_command_argument(3, arg, status)
        infile1 = TRIM(arg)

        ! Now check for optional  argument for year (use for checking NCEP files
        call date_and_time(VALUES=values)
        Current_Year = values(1)
        if(nargs.gt.3)then
          call get_command_argument(4, arg, status)
          read(arg,*)iy
        else
          iy = Current_Year
        endif
        !MR_Comp_StartHour     = HS_hours_since_baseyear(iy,1,1,0.0_8,1900,.True.)
        !MR_Comp_Time_in_hours = 1.0
      endif

      write(MR_global_info,*)"Set up windfile data structure"
      if(iwf.eq.25)then
        iw      = 5
        MR_Comp_StartHour     = HS_hours_since_baseyear(iy,1,1,0.0_8,1900,.True.)
        MR_Comp_Time_in_hours = 1.0
      else
        iw      = 4
      endif
      igrid   = 0  ! this will get reset in MR_Allocate_FullMetFileList
      iwfiles = 1
      call MR_Allocate_FullMetFileList(iw,iwf,igrid,idf,iwfiles)
      write(MR_windfiles(1),*)trim(ADJUSTL(infile1))

        ! Check for windfile existance and read their sizes
      call MR_Read_Met_DimVars(iy)

      ! This allows us to pass zero's for starttime and duration and get
      ! the whole metstep list
      MR_useCompTime = .false.
      call MR_Set_Met_Times(0.0_8,0.0_8)

      ! These are dummy values.
      !nxmax = 3 !
      !nymax = 3 !
      nxmax = 2 !
      nymax = 2 !

      nzmax = 2 ! This is not really used in this utility
      inlon = 0.0_4
      inlat = 0.0_4
      !allocate(lon_grid(nxmax)); lon_grid(1:3) = (/inlon-0.5_4,inlon,inlon+0.5_4/)
      !allocate(lat_grid(nymax)); lat_grid(1:3) = (/inlat-0.5_4,inlat,inlat+0.5_4/)
      allocate(lon_grid(nxmax)); lon_grid(1:nxmax) = (/inlon-0.5_4,inlon+0.5_4/)
      allocate(lat_grid(nymax)); lat_grid(1:nymax) = (/inlat-0.5_4,inlat+0.5_4/)

      allocate(z_cc(nzmax))    ; z_cc(1:2) = (/0.0_4, 10.0_4/)
      IsPeriodic = .false.

      ! We just want to access the met grid, so set our 'comp' grid to the
      ! same projection
      IsLatLon     = IsLatLon_MetGrid
      iprojflag    = Met_iprojflag
      lambda0      = Met_lam0
      phi0         = Met_phi0
      phi1         = Met_phi1
      phi2         = Met_phi2
      k0           = Met_k0
      radius_earth = Met_Re
      call MR_Set_CompProjection(IsLatLon,iprojflag,lambda0,phi0,phi1,phi2,&
                                 k0,radius_earth)

      ! This program needs no interpolation so we need to explicitly
      ! declare that we do not need a computational grid defined
      MR_useCompGrid = .false.

      call MR_Initialize_Met_Grids(nxmax,nymax,nzmax,&
                              lon_grid(1:nxmax), &
                              lat_grid(1:nymax), &
                              z_cc(1:nzmax)    , &
                              IsPeriodic)
      ! We need to populate the HGT arrays or the vertical velocity read with fail
      ! since the conversion relies on dp/dz
      call MR_Read_HGT_arrays(1)  ! Just fill with the geopotential height at step 1

      open(unit=19,iostat=stat,file='MetCheck_log.txt',status='old')
      if (stat == 0) close(19, status='delete')

      open(unit=19,file='MetCheck_log.txt',status='replace')

      do imetstep = 1,nt_fullmet
        do ivar=1,5
          idx = Met_var_zdim_idx(ivar)
          if(Met_dim_IsAvailable(ivar).eqv..true.)then
            np = nlevs_fullmet(idx)
            v1 = Met_var_MinMax(ivar,1)
            v2 = Met_var_MinMax(ivar,2)
            call MR_Read_3d_MetP_Variable(ivar,imetstep)
            do i=1,nx_fullmet
              do j=1,ny_fullmet
                do p=1,np
                  tmp=MR_dum3d_metP(i,j,p)
                  if(tmp.lt.v1.or.tmp.gt.v2)then
                    write(MR_global_info,*)"ERROR reading value for ivar=",ivar
                    write(MR_global_info,*)"      at i,j,p = ",i,j,p
                    write(MR_global_info,*)"      Value read = ",tmp
                    write(MR_global_info,*)"      Min / Max = ",v1,v2
                    stop 1
                  endif
                enddo
              enddo
            enddo
          endif
        enddo

        if(iwf.eq.25)then
          write(19,*)adjustl(trim(MR_windfiles(1)))," : ", &
                     imetstep                      ," : ", &
                     iy                            ," : ", &
                     real((imetstep-1),kind=4)*6.0_4/24_4
        else
          hsince = MR_windfile_starthour(1)+MR_windfile_stephour(1,imetstep)
          write(19,*)adjustl(trim(MR_windfiles(1)))," : ", &
                     imetstep                      ," : ", &
                     HS_YearOfEvent(hsince,MR_BaseYear,MR_useLeap)," : ",&
                     real(HS_DayOfYear(hsince,MR_BaseYear,MR_useLeap)+ &
                       HS_HourOfDay(hsince,MR_BaseYear,MR_useLeap)/24.0_8,kind=4)
        endif

      enddo

      close(19)
      write(MR_global_info,*)"Program ended normally."

      end program MetCheck


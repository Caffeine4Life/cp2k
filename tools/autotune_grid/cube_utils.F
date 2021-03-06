MODULE cube_utils

  USE kinds,                           ONLY: dp

  IMPLICIT NONE

  PUBLIC :: cube_info_type
  PUBLIC :: cube_ptr
  PUBLIC :: init_cube_info
  PUBLIC :: destroy_cube_info
  PUBLIC :: return_cube

  TYPE :: cube_ptr
       INTEGER, POINTER, DIMENSION(:) :: p
  END TYPE cube_ptr

  TYPE :: cube_info_type
     INTEGER                      :: max_radius
     REAL(KIND = dp)              :: dr(3),drmin,drsafe
     REAL(KIND = dp)              :: dh(3,3)
     LOGICAL                      :: orthorhombic
     INTEGER, POINTER             :: lb_cube(:,:)
     INTEGER, POINTER             :: ub_cube(:,:)
     TYPE(cube_ptr), POINTER, DIMENSION(:)  :: sphere_bounds
     INTEGER, POINTER             :: sphere_bounds_count(:)
     REAL(KIND = dp)              :: max_rad_ga
  END TYPE cube_info_type

!------------------------------------------------------------------------------

CONTAINS

!------------------------------------------------------------------------------
  SUBROUTINE return_cube(info,radius,lb_cube,ub_cube,sphere_bounds)
    TYPE(cube_info_type)                     :: info
    REAL(KIND=dp)                            :: radius
    INTEGER                                  :: lb_cube(3), ub_cube(3)
    INTEGER, DIMENSION(:), POINTER           :: sphere_bounds

    INTEGER                                  :: imr

    imr=MAX(1,CEILING((radius+info%drsafe)/info%drmin))
    IF (imr.gt.info%max_radius) THEN
        imr = info%max_radius
    ENDIF
    lb_cube(:)       = info%lb_cube(:,imr)
    ub_cube(:)       = info%ub_cube(:,imr)
    sphere_bounds => info%sphere_bounds(imr)%p

  RETURN
  END SUBROUTINE return_cube

!------------------------------------------------------------------------------

  SUBROUTINE destroy_cube_info(info)
    TYPE(cube_info_type)                     :: info

    CHARACTER(LEN=*), PARAMETER :: &
      routine = "SUBROUTINE destroy_cube_info (MODULE cube_utils)"

    INTEGER                                  :: i, istat

    DEALLOCATE (info%lb_cube,STAT=istat)
    DEALLOCATE (info%ub_cube,STAT=istat)
    DEALLOCATE (info%sphere_bounds_count,STAT=istat)
    DO i=1,info%max_radius
      DEALLOCATE (info%sphere_bounds(i)%p,STAT=istat)
    END DO
    DEALLOCATE (info%sphere_bounds,STAT=istat)
  END SUBROUTINE

!------------------------------------------------------------------------------

  SUBROUTINE init_cube_info(info,dr,dh,ortho,max_radius,cmax)
    TYPE(cube_info_type)                     :: info
    REAL(KIND=dp)                            :: dr(3), dh(3,3)
    LOGICAL                                  :: ortho
    INTEGER                                  :: max_radius
    INTEGER                                  :: cmax

    CHARACTER(LEN=*), PARAMETER :: &
      routine = "SUBROUTINE init_cube_info (MODULE cube_utils)"

    INTEGER                                  :: check_1, check_2, i, &
                                                igmin, imr, istat, jg, jg2, &
                                                jgmin, k, kg, kg2, kgmin
    REAL(KIND=dp)                            :: drmin, dxi, dy2, dyi, &
                                                dz2, dzi, radius, radius2

    info%dr = dr
    info%dh = dh
    info%orthorhombic = ortho
    drmin = MINVAL(dr)
    info%drmin=drmin
    info%drsafe=0
    imr=max_radius
    info%max_radius=imr
    dzi=1.0_dp/dr(3)
    dyi=1.0_dp/dr(2)
    dxi=1.0_dp/dr(1)
    dz2=(dr(3))**2
    dy2=(dr(2))**2

    IF ( .NOT. info%orthorhombic ) THEN
    END IF

    NULLIFY(info%lb_cube,info%ub_cube,&
            info%sphere_bounds_count,info%sphere_bounds)
    ALLOCATE(info%lb_cube(3,imr),info%ub_cube(3,imr), &
             info%sphere_bounds_count(imr),info%sphere_bounds(imr))
    cmax=0
    check_1=0
    check_2=0
!   count and allocate

    DO i=1,imr
      k=1
      radius=i*drmin 
      radius2=radius**2
      kgmin=do_and_hide_it_1(dzi,i,drmin,0.0_dp,0.0_dp,0,0)
      k=k+1
      DO kg=kgmin,0
         kg2=kg*kg
         jgmin=do_and_hide_it_1(dyi,i,drmin,dz2,0.0_dp,kg2,0)
         k=k+1
         DO jg=jgmin,0
          jg2=jg*jg
          igmin=do_and_hide_it_1(dxi,i,drmin,dz2,dy2,kg2,jg2)
          check_1=MODULO((kgmin*97+jgmin*37+igmin*113)*check_1+1277,9343)
          k=k+1
         ENDDO
      ENDDO
      info%sphere_bounds_count(i)=k-1
      ALLOCATE (info%sphere_bounds(i)%p(info%sphere_bounds_count(i)),STAT=istat)
    ENDDO

!   init sphere_bounds array
    ! notice : as many points in lb_cube..0 as 1..ub_cube
    DO i=1,imr 
      k=1
      radius=i*drmin
      info%lb_cube(:,i)=-1
      radius2=radius**2
      kgmin=do_and_hide_it_1(dzi,i,drmin,0.0_dp,0.0_dp,0,0)
      info%lb_cube(3,i)=MIN(kgmin,info%lb_cube(3,i))
      info%sphere_bounds(i)%p(k)=kgmin
      k=k+1
      DO kg=kgmin,0
         kg2=kg*kg
         jgmin=do_and_hide_it_1(dyi,i,drmin,dz2,0.0_dp,kg2,0)
         info%lb_cube(2,i)=MIN(jgmin,info%lb_cube(2,i))
         info%sphere_bounds(i)%p(k)=jgmin
         k=k+1
         DO jg=jgmin,0
          jg2=jg*jg
          igmin=do_and_hide_it_1(dxi,i,drmin,dz2,dy2,kg2,jg2)
          check_2=MODULO((kgmin*97+jgmin*37+igmin*113)*check_2+1277,9343)
          info%lb_cube(1,i)=MIN(igmin,info%lb_cube(1,i))
          info%sphere_bounds(i)%p(k)=igmin
          k=k+1
         ENDDO
      ENDDO
      info%ub_cube(:,i)=1-info%lb_cube(:,i)
    ENDDO
    cmax=MAXVAL(info%ub_cube)
    IF (check_1.NE.check_2) THEN 
                          STOP " :-/ irreproducible fp math caused memory corruption"
    ENDIF
  END SUBROUTINE
  ! try to hide things from the optimizer, so that we get the same numbers,
  ! always (this solves the optimisation problems with the intel and nag compiler
  ! in which the counting loops and execution loops above are executed a different
  ! number of times, even at -O1
  FUNCTION do_and_hide_it_1(prefactor,i,drmin,dz2,dy2,kg2,jg2) RESULT(res)
    REAL(KIND=dp)                            :: prefactor
    INTEGER                                  :: i
    REAL(KIND=dp)                            :: drmin, dz2, dy2
    INTEGER                                  :: kg2, jg2, res

    REAL(KIND=dp), DIMENSION(:), POINTER     :: buf

    ALLOCATE(buf(4))
    buf(1)=prefactor
    buf(2)=drmin
    buf(3)=dz2
    buf(4)=dy2
    res=do_and_hide_it_2(buf,i,jg2,kg2)
    DEALLOCATE(buf)
  END FUNCTION do_and_hide_it_1
  FUNCTION do_and_hide_it_2(buf,i,jg2,kg2) RESULT(res)
    REAL(KIND=dp), DIMENSION(:), POINTER     :: buf
    INTEGER                                  :: i, jg2, kg2, res

    buf(2)=(i*buf(2))**2
    res = CEILING(-0.1E-7_dp-buf(1)*SQRT(MAX(buf(2)-kg2*buf(3)-jg2*buf(4),0.0_dp)))
  END FUNCTION do_and_hide_it_2
! *****************************************************************************

END MODULE

! *****************************************************************************

!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2018  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Writes information on XC functionals to output
! **************************************************************************************************
MODULE xc_write_output

   USE input_constants,                 ONLY: xc_none
   USE input_cp2k_check,                ONLY: xc_functionals_expand
   USE input_section_types,             ONLY: section_vals_duplicate,&
                                              section_vals_get,&
                                              section_vals_get_subs_vals,&
                                              section_vals_get_subs_vals2,&
                                              section_vals_release,&
                                              section_vals_type,&
                                              section_vals_val_get
   USE kinds,                           ONLY: default_string_length
   USE xc_derivatives,                  ONLY: xc_functional_get_info
   USE xc_libxc,                        ONLY: libxc_version_info
#include "./base/base_uses.f90"

   IMPLICIT NONE

   PRIVATE

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'xc_write_output'

   PUBLIC :: xc_write

CONTAINS

! **************************************************************************************************
!> \brief ...
!> \param output_unit ...
!> \param xc_section ...
!> \param lsd ...
! **************************************************************************************************
   SUBROUTINE xc_write(output_unit, xc_section, lsd)
      INTEGER, INTENT(IN)                                :: output_unit
      TYPE(section_vals_type), POINTER                   :: xc_section
      LOGICAL, INTENT(IN)                                :: lsd

      CHARACTER(len=*), PARAMETER :: routineN = 'xc_write', routineP = moduleN//':'//routineN

      CHARACTER(LEN=10*default_string_length)            :: reference
      CHARACTER(LEN=2*default_string_length)             :: shortform
      CHARACTER(LEN=20)                                  :: tmpStr
      INTEGER                                            :: i_rep, ifun, il, myfun, n_rep
      TYPE(section_vals_type), POINTER                   :: libxc_fun, xc_fun, xc_fun_section

      IF (output_unit > 0) THEN

         xc_fun_section => section_vals_get_subs_vals(xc_section, &
                                                      "XC_FUNCTIONAL")
         CALL section_vals_val_get(xc_fun_section, "_SECTION_PARAMETERS_", i_val=myfun)
         IF (myfun /= xc_none) THEN
            CALL section_vals_val_get(xc_section, "FUNCTIONAL_ROUTINE", &
                                      c_val=tmpStr)
            WRITE (output_unit, fmt="(' FUNCTIONAL| ROUTINE=',a)") &
               TRIM(tmpStr)
            CALL xc_functionals_expand(xc_fun_section, xc_section)
            ifun = 0
            DO
               ifun = ifun+1
               xc_fun => section_vals_get_subs_vals2(xc_fun_section, i_section=ifun)
               IF (.NOT. ASSOCIATED(xc_fun)) EXIT
               IF (TRIM(xc_fun%section%name) /= "LIBXC") THEN
                  CALL xc_functional_get_info(xc_fun, lsd=lsd, reference=reference, shortform=shortform)
                  WRITE (output_unit, fmt="(' FUNCTIONAL| ',a,':')") &
                     TRIM(xc_fun%section%name)
                  DO il = 1, LEN_TRIM(reference), 67
                     WRITE (output_unit, fmt="(' FUNCTIONAL| ',a67)") reference(il:)
                  END DO
               ELSE
                  ! LIBXC is the only repeatable functional section - for each we need
                  ! NOT the single values, but the whole section_vals_type independently
                  CALL section_vals_get(xc_fun, n_repetition=n_rep)
                  DO i_rep = 1, n_rep
                     NULLIFY (libxc_fun)
                     CALL section_vals_duplicate(xc_fun, libxc_fun, i_rep_start=i_rep, i_rep_end=i_rep)
                     IF (.NOT. ASSOCIATED(libxc_fun)) EXIT
                     CALL xc_functional_get_info(libxc_fun, lsd=lsd, reference=reference, shortform=shortform)
                     CALL section_vals_release(libxc_fun)
                     CALL libxc_version_info(tmpStr)
                     WRITE (output_unit, fmt="(A,A,A)") ' FUNCTIONAL| LIBXC Vers. ', TRIM(tmpStr(1:5)), &
                        ' (Marques, Oliveira, Burnus, CPC 183, 2272 (2012))'
                     WRITE (output_unit, fmt="(' FUNCTIONAL| ',a,':')") TRIM(shortform)
                     DO il = 1, LEN_TRIM(reference), 67
                        WRITE (output_unit, fmt="(' FUNCTIONAL| ',a67)") reference(il:)
                     END DO
                  END DO
               END IF
            END DO
         ELSE
            WRITE (output_unit, fmt="(' FUNCTIONAL| NO EXCHANGE-CORRELATION FUNCTIONAL USED.')")
         END IF
      END IF

   END SUBROUTINE xc_write

END MODULE xc_write_output

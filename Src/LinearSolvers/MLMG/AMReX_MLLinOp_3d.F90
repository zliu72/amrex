
#include "AMReX_LO_BCTYPES.H"

module amrex_mllinop_3d_module

  use amrex_error_module
  use amrex_fort_module, only : amrex_real
  implicit none
  
  private
  public :: amrex_mllinop_apply_bc, amrex_mllinop_comp_interp_coef0

contains

  subroutine amrex_mllinop_apply_bc (lo, hi, phi, hlo, hhi, mask, mlo, mhi, &
       cdir, bct, bcl, bcval, blo, bhi, maxorder, dxinv, inhomog) &
       bind(c,name='amrex_mllinop_apply_bc')
    integer, dimension(3), intent(in) :: lo, hi, hlo, hhi, mlo, mhi, blo, bhi
    integer, value, intent(in) :: cdir, bct, maxorder, inhomog
    real(amrex_real), value, intent(in) :: bcl
    real(amrex_real), intent(in) :: dxinv(3)
    real(amrex_real), intent(inout) ::  phi (hlo(1):hhi(1),hlo(2):hhi(2),hlo(3):hhi(3))
    integer         , intent(in   ) :: mask (mlo(1):mhi(1),mlo(2):mhi(2),mlo(3):mhi(3))
    real(amrex_real), intent(in   ) :: bcval(blo(1):bhi(1),blo(2):bhi(2),blo(3):bhi(3))

    integer :: i, j, k, idim, lenx, m
    logical :: inhomogeneous
    real(amrex_real) ::    x(-1:maxorder-2)
    real(amrex_real) :: coef(-1:maxorder-2), coef2(-maxorder+2:1)
    real(amrex_real), parameter :: xInt = -0.5D0
    real(amrex_real) :: fac

    inhomogeneous = (inhomog .ne. 0)
    
    if (bct == LO_NEUMANN .or. bct == LO_REFLECT_ODD) then

       if (bct == LO_NEUMANN) then
          fac = 1.d0
       else
          fac = -1.d0
       end if
       
       select case (cdir)
       case (0)  ! xlo
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                if (mask(lo(1)-1,j,k) .gt. 0) then
                   phi(lo(1)-1,j,k) = fac*phi(lo(1),j,k)
                end if
             end do
          end do
       case (3)  ! xhi
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                if (mask(hi(1)+1,j,k) .gt. 0) then
                   phi(hi(1)+1,j,k) = fac*phi(hi(1),j,k)
                end if
             end do
          end do
       case (1)  ! ylo
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                if (mask(i,lo(2)-1,k) .gt. 0) then
                   phi(i,lo(2)-1,k) = fac*phi(i,lo(2),k)
                end if
             end do
          end do
       case (4)  ! yhi
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                if (mask(i,hi(2)+1,k) .gt. 0) then
                   phi(i,hi(2)+1,k) = fac*phi(i,hi(2),k)
                end if
             end do
          end do
       case (2)  ! zlo
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                if (mask(i,j,lo(3)-1) .gt. 0) then
                   phi(i,j,lo(3)-1) = fac*phi(i,j,lo(3))
                end if
             end do
          end do
       case (5)  ! zhi
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                if (mask(i,j,hi(3)+1) .gt. 0) then
                   phi(i,j,hi(3)+1) = fac*phi(i,j,hi(3))
                end if
             end do
          end do
       end select

    else if (bct == LO_DIRICHLET) then

       idim = mod(cdir,3) + 1 ! cdir starts with 0; idim starts with 1
       lenx = MIN(hi(idim)-lo(idim), maxorder-2)
       
       x(-1) = -bcl*dxinv(idim)
       do m=0,maxorder-2
          x(m) = m + 0.5D0
       end do
       
       call polyInterpCoeff(xInt, x, lenx+2, coef)
       do m = -lenx, 1
          coef2(m) = coef(-m)
       end do

       select case (cdir)
       case (0)  ! xlo
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                if (mask(lo(1)-1,j,k) .gt. 0) then
                   phi(lo(1)-1,j,k) = sum(phi(lo(1):lo(1)+lenx,j,k)*coef(0:lenx))
                   if (inhomogeneous) then
                      phi(lo(1)-1,j,k) = phi(lo(1)-1,j,k) + bcval(lo(1)-1,j,k)*coef(-1)
                   end if
                end if
             end do
          end do
       case (3)  ! xhi
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                if (mask(hi(1)+1,j,k) .gt. 0) then
                   phi(hi(1)+1,j,k) = sum(phi(hi(1)-lenx:hi(1),j,k)*coef2(-lenx:0))
                   if (inhomogeneous) then
                      phi(hi(1)+1,j,k) = phi(hi(1)+1,j,k) + bcval(hi(1)+1,j,k)*coef2(1)
                   end if
                end if
             end do
          end do
       case (1)  ! ylo
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                if (mask(i,lo(2)-1,k) .gt. 0) then
                   phi(i,lo(2)-1,k) = sum(phi(i,lo(2):lo(2)+lenx,k)*coef(0:lenx))
                   if (inhomogeneous) then
                      phi(i,lo(2)-1,k) = phi(i,lo(2)-1,k) + bcval(i,lo(2)-1,k)*coef(-1)
                   end if
                end if
             end do
          end do
       case (4)  ! yhi
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                if (mask(i,hi(2)+1,k) .gt. 0) then
                   phi(i,hi(2)+1,k) = sum(phi(i,hi(2)-lenx:hi(2),k)*coef2(-lenx:0))
                   if (inhomogeneous) then
                      phi(i,hi(2)+1,k) = phi(i,hi(2)+1,k) + bcval(i,hi(2)+1,k)*coef2(1)
                   end if
                end if
             end do
          end do
       case (2)  ! zlo
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                if (mask(i,j,lo(3)-1) .gt. 0) then
                   phi(i,j,lo(3)-1) = sum(phi(i,j,lo(3):lo(3)+lenx)*coef(0:lenx))
                   if (inhomogeneous) then
                      phi(i,j,lo(3)-1) = phi(i,j,lo(3)-1) + bcval(i,j,lo(3)-1)*coef(-1)
                   end if
                end if
             end do
          end do
       case (5)  ! zhi
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                if (mask(i,j,hi(3)+1) .gt. 0) then
                   phi(i,j,hi(3)+1) = sum(phi(i,j,hi(3)-lenx:hi(3))*coef2(-lenx:0))
                   if (inhomogeneous) then
                      phi(i,j,hi(3)+1) = phi(i,j,hi(3)+1) + bcval(i,j,hi(3)+1)*coef2(1)
                   end if
                end if
             end do
          end do
       end select

    else
       call amrex_error("amrex_mllinop_3d_module: unknown bc");
    end if

  end subroutine amrex_mllinop_apply_bc


  subroutine amrex_mllinop_comp_interp_coef0 (lo, hi, den, dlo, dhi, mask, mlo, mhi, &
       cdir, bct, bcl, maxorder, dxinv) bind(c,name='amrex_mllinop_comp_interp_coef0')
    integer, dimension(3), intent(in) :: lo, hi, dlo, dhi, mlo, mhi
    integer, value, intent(in) :: cdir, bct, maxorder
    real(amrex_real), value, intent(in) :: bcl
    real(amrex_real), intent(in) :: dxinv(3)
    real(amrex_real), intent(inout) ::  den(dlo(1):dhi(1),dlo(2):dhi(2),dlo(3):dhi(3))
    integer         , intent(in   ) :: mask(mlo(1):mhi(1),mlo(2):mhi(2),mlo(3):mhi(3))

    integer :: i,j,k,idim,lenx,m
    real(amrex_real) ::    x(-1:maxorder-2)
    real(amrex_real) :: coef(-1:maxorder-2)
    real(amrex_real), parameter :: xInt = -0.5D0
    real(amrex_real) :: c0
    
    if (bct == LO_NEUMANN) then

       select case (cdir)
       case (0)  ! xlo
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                den(lo(1),j,k) = 1.d0
             end do
          end do
       case (3)  ! xhi
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                den(hi(1),j,k) = 1.d0
             end do
          end do
       case (1)  ! ylo
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                den(i,lo(2),k) = 1.d0
             end do
          end do
       case (4)  ! yhi
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                den(i,hi(2),k) = 1.d0
             end do
          end do
       case (2)  ! zlo
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                den(i,j,lo(3)) = 1.d0
             end do
          end do
       case (5)  ! zhi
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                den(i,j,hi(3)) = 1.d0
             end do
          end do
       end select

    else if (bct == LO_REFLECT_ODD .or. bct == LO_DIRICHLET) then

       if (bct == LO_REFLECT_ODD) then
          c0 = 1.d0
       else
          idim = mod(cdir,3) + 1 ! cdir starts with 0; idim starts with 1
          lenx = MIN(hi(idim)-lo(idim), maxorder-2)
          
          x(-1) = -bcl*dxinv(idim)
          do m=0,maxorder-2
             x(m) = m + 0.5D0
          end do
          
          call polyInterpCoeff(xInt, x, lenx+2, coef)

          c0 = coef(0)
       end if
       
       select case (cdir)
       case (0)  ! xlo
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                if (mask(lo(1)-1,j,k) .gt. 0) then
                   den(lo(1),j,k) = c0
                else
                   den(lo(1),j,k) = 0.d0
                end if
             end do
          end do
       case (3)  ! xhi
          do    k = lo(3), hi(3)
             do j = lo(2), hi(2)
                if (mask(hi(1)+1,j,k) .gt. 0) then
                   den(hi(1),j,k) = c0
                else
                   den(hi(1),j,k) = 0.d0
                end if
             end do
          end do
       case (1)  ! ylo
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                if (mask(i,lo(2)-1,k) .gt. 0) then
                   den(i,lo(2),k) = c0
                else
                   den(i,lo(2),k) = 0.d0
                end if
             end do
          end do
       case (4)  ! yhi
          do    k = lo(3), hi(3)
             do i = lo(1), hi(1)
                if (mask(i,hi(2)+1,k) .gt. 0) then
                   den(i,hi(2),k) = c0
                else
                   den(i,hi(2),k) = 0.d0
                end if
             end do
          end do
       case (2)  ! zlo
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                if (mask(i,j,lo(3)-1) .gt. 0) then
                   den(i,j,lo(3)) = c0
                else
                   den(i,j,lo(3)) = 0.d0
                end if
             end do
          end do
       case (5)  ! zhi
          do    j = lo(2), hi(2)
             do i = lo(1), hi(1)
                if (mask(i,j,hi(3)+1) .gt. 0) then
                   den(i,j,hi(3)) = c0
                else
                   den(i,j,hi(3)) = 0.d0
                end if
             end do
          end do
       end select
       
    end if
    
  end subroutine amrex_mllinop_comp_interp_coef0
  
end module amrex_mllinop_3d_module

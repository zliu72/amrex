
subroutine advectDiffGodunov(time, lo, hi, &
     &            uin , ui_lo, ui_hi, &
     &            dphidtout, uo_lo, uo_hi, &
     &            vx  , vx_lo, vx_hi, &
     &            vy  , vy_lo, vy_hi, &
     &            flxx, fx_lo, fx_hi, &
     &            flxy, fy_lo, fy_hi, &
     &            dx,dt, nu) bind(C, name="advectDiffGodunov")
  
  use mempool_module, only : bl_allocate, bl_deallocate
  use compute_flux_module, only : godunov_flux_2d

  implicit none

  integer, intent(in) :: lo(2), hi(2)
  double precision, intent(in) :: dx(2), dt, time, nu
  integer, intent(in) :: ui_lo(2), ui_hi(2)
  integer, intent(in) :: uo_lo(2), uo_hi(2)
  integer, intent(in) :: vx_lo(2), vx_hi(2)
  integer, intent(in) :: vy_lo(2), vy_hi(2)
  integer, intent(in) :: fx_lo(2), fx_hi(2)
  integer, intent(in) :: fy_lo(2), fy_hi(2)
  double precision, intent(in   ) :: uin (ui_lo(1):ui_hi(1),ui_lo(2):ui_hi(2))
  double precision, intent(inout) :: dphidtout(uo_lo(1):uo_hi(1),uo_lo(2):uo_hi(2))
  double precision, intent(in   ) :: vx  (vx_lo(1):vx_hi(1),vx_lo(2):vx_hi(2))
  double precision, intent(in   ) :: vy  (vy_lo(1):vy_hi(1),vy_lo(2):vy_hi(2))
  double precision, intent(  out) :: flxx(fx_lo(1):fx_hi(1),fx_lo(2):fx_hi(2))
  double precision, intent(  out) :: flxy(fy_lo(1):fy_hi(1),fy_lo(2):fy_hi(2))

  integer :: i, j
  integer :: glo(2), ghi(2)
  double precision :: umax, vmax

  ! Some compiler may not support 'contiguous'.  Remove it in that case.
  double precision, dimension(:,:), pointer, contiguous :: phix_1d, phiy_1d, phix, phiy, slope

  glo = lo - 1
  ghi = hi + 1

  ! edge states
  call bl_allocate(phix_1d, glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(phiy_1d, glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(phix   , glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(phiy   , glo(1), ghi(1), glo(2), ghi(2))
  ! slope                                                 
  call bl_allocate(slope  , glo(1), ghi(1), glo(2), ghi(2))

  ! We like to allocate these **pointers** here and then pass them to a function
  ! to remove their pointerness for performance, because normally pointers could
  ! be aliasing.  We need to use pointers instead of allocatable arrays because
  ! we like to use BoxLib's bl_allocate to allocate memeory instead of the intrinsic
  ! allocate.  Bl_allocate is much faster than allocate inside OMP.  
  ! Note that one MUST CALL BL_DEALLOCATE.

  ! check if CFL condition is violated.
  umax = maxval(abs(vx))
  vmax = maxval(abs(vy))

  if ( umax*dt .ge. dx(1) .or. &
       vmax*dt .ge. dx(2) ) then
     print *, "umax = ", umax, ", vmax = ", vmax, ", dt = ", dt, ", dx = ", dx
     call bl_error("CFL violation. Use smaller adv.cfl.")
  end if

  ! call a function to compute flux
  call godunov_flux_2d(lo, hi, dt, dx, &
                       uin, ui_lo, ui_hi, &
                       vx, vx_lo, vx_hi, &
                       vy, vy_lo, vy_hi, &
                       flxx, fx_lo, fx_hi, &
                       flxy, fy_lo, fy_hi, &
                       phix_1d, phiy_1d, phix, phiy, slope, glo, ghi, nu)


  ! Do a conservative update
  do    j = lo(2),hi(2)
     do i = lo(1),hi(1)
        !notice that some mad scientist has reversed the flux difference
        ! rather than just put a negative sign out front.
        dphidtout(i,j) = &
             ( (flxx(i,j) - flxx(i+1,j  )) / dx(1) &
             + (flxy(i,j) - flxy(i  ,j+1)) / dx(2) )
     enddo
  enddo

  ! Scale by face area in order to correctly reflux because flux register requires this
  do    j = lo(2), hi(2)
     do i = lo(1), hi(1)+1
        flxx(i,j) = flxx(i,j) * ( dt * dx(2))
     enddo
  enddo
  
  ! Scale by face area in order to correctly reflux because flux register requires this
  do    j = lo(2), hi(2)+1 
     do i = lo(1), hi(1)
        flxy(i,j) = flxy(i,j) * (dt * dx(1))
     enddo
  enddo

  call bl_deallocate(phix_1d)
  call bl_deallocate(phiy_1d)
  call bl_deallocate(phix)
  call bl_deallocate(phiy)
  call bl_deallocate(slope)

end subroutine advectDiffGodunov

subroutine advectDiffMOL2ndOrd(time, lo, hi, &
     &            uin , ui_lo, ui_hi, &
     &            dphidtout, uo_lo, uo_hi, &
     &            vx  , vx_lo, vx_hi, &
     &            vy  , vy_lo, vy_hi, &
     &            flxx, fx_lo, fx_hi, &
     &            flxy, fy_lo, fy_hi, &
     &            dx,dt, nu) bind(C, name="advectDiffMOL2ndOrd")
  
  use mempool_module, only : bl_allocate, bl_deallocate
  use compute_flux_module, only : mol2ndord_flux_2d

  implicit none

  integer, intent(in) :: lo(2), hi(2)
  double precision, intent(in) :: dx(2), dt, time, nu
  integer, intent(in) :: ui_lo(2), ui_hi(2)
  integer, intent(in) :: uo_lo(2), uo_hi(2)
  integer, intent(in) :: vx_lo(2), vx_hi(2)
  integer, intent(in) :: vy_lo(2), vy_hi(2)
  integer, intent(in) :: fx_lo(2), fx_hi(2)
  integer, intent(in) :: fy_lo(2), fy_hi(2)
  double precision, intent(in   ) :: uin (ui_lo(1):ui_hi(1),ui_lo(2):ui_hi(2))
  double precision, intent(inout) :: dphidtout(uo_lo(1):uo_hi(1),uo_lo(2):uo_hi(2))
  double precision, intent(in   ) :: vx  (vx_lo(1):vx_hi(1),vx_lo(2):vx_hi(2))
  double precision, intent(in   ) :: vy  (vy_lo(1):vy_hi(1),vy_lo(2):vy_hi(2))
  double precision, intent(  out) :: flxx(fx_lo(1):fx_hi(1),fx_lo(2):fx_hi(2))
  double precision, intent(  out) :: flxy(fy_lo(1):fy_hi(1),fy_lo(2):fy_hi(2))

  integer :: i, j
  integer :: glo(2), ghi(2)
  double precision :: umax, vmax, fhi, flo

  ! Some compiler may not support 'contiguous'.  Remove it in that case.
  double precision, dimension(:,:), pointer, contiguous :: phix_1d, phiy_1d, slope

  glo = lo - 1
  ghi = hi + 1

  ! edge states
  call bl_allocate(phix_1d, glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(phiy_1d, glo(1), ghi(1), glo(2), ghi(2))
  ! slope                                                 
  call bl_allocate(slope  , glo(1), ghi(1), glo(2), ghi(2))

  ! We like to allocate these **pointers** here and then pass them to a function
  ! to remove their pointerness for performance, because normally pointers could
  ! be aliasing.  We need to use pointers instead of allocatable arrays because
  ! we like to use BoxLib's bl_allocate to allocate memeory instead of the intrinsic
  ! allocate.  Bl_allocate is much faster than allocate inside OMP.  
  ! Note that one MUST CALL BL_DEALLOCATE.

  ! check if CFL condition is violated.
  umax = maxval(abs(vx))
  vmax = maxval(abs(vy))
  if ( umax*dt .ge. dx(1) .or. &
       vmax*dt .ge. dx(2) ) then
     print *, "umax = ", umax, ", vmax = ", vmax, ", dt = ", dt, ", dx = ", dx
     call bl_error("CFL violation. Use smaller adv.cfl.")
  end if

  ! call a function to compute flux
  call mol2ndord_flux_2d(lo, hi, dt, dx, &
       uin, ui_lo, ui_hi, &
       vx, vx_lo, vx_hi, &
       vy, vy_lo, vy_hi, &
       flxx, fx_lo, fx_hi, &
       flxy, fy_lo, fy_hi, &
       phix_1d, phiy_1d,  slope, glo, ghi, nu)


  ! Do a conservative update
  do    j = lo(2),hi(2)
     do i = lo(1),hi(1)
        !notice that some mad scientist has reversed the flux difference
        ! rather than just put a negative sign out front.
        flo = flxx(i,j)
        fhi = flxx(i+1,j)
        fhi = flxy(i,j+1)
        flo = flxy(i,j  )
        dphidtout(i,j) = &
             ( (flxx(i,j) - flxx(i+1,j  )) / dx(1) &
             + (flxy(i,j) - flxy(i  ,j+1)) / dx(2) )
     enddo
  enddo

  ! Scale by face area in order to correctly reflux because flux register requires this
  do    j = lo(2), hi(2)
     do i = lo(1), hi(1)+1
        flxx(i,j) = flxx(i,j) * ( dt * dx(2))
     enddo
  enddo
  
  ! Scale by face area in order to correctly reflux because flux register requires this
  do    j = lo(2), hi(2)+1 
     do i = lo(1), hi(1)
        flxy(i,j) = flxy(i,j) * (dt * dx(1))
     enddo
  enddo

  call bl_deallocate(phix_1d)
  call bl_deallocate(phiy_1d)
  call bl_deallocate(slope)

end subroutine advectDiffMOL2ndOrd



subroutine advectDiffMOL4thOrd(time, lo, hi, &
     &            uin , ui_lo, ui_hi, &
     &            dphidtout, uo_lo, uo_hi, &
     &            vx  , vx_lo, vx_hi, &
     &            vy  , vy_lo, vy_hi, &
     &            flxx, fx_lo, fx_hi, &
     &            flxy, fy_lo, fy_hi, &
     &            dx,dt, nu,          &
     &            deblocell, debhicell, &
     &            debloface, debhiface &
     ) bind(C, name="advectDiffMOL4thOrd")
  
  use mempool_module, only : bl_allocate, bl_deallocate
  use compute_flux_module, only : mol4thord_flux_2d

  implicit none

  integer, intent(in) :: lo(2), hi(2)
  integer, intent(in) :: deblocell(2), debhicell(2), debloface(2), debhiface(2)
  double precision, intent(in) :: dx(2), dt, time, nu
  integer, intent(in) :: ui_lo(2), ui_hi(2)
  integer, intent(in) :: uo_lo(2), uo_hi(2)
  integer, intent(in) :: vx_lo(2), vx_hi(2)
  integer, intent(in) :: vy_lo(2), vy_hi(2)
  integer, intent(in) :: fx_lo(2), fx_hi(2)
  integer, intent(in) :: fy_lo(2), fy_hi(2)
  double precision, intent(in   ) :: uin (ui_lo(1):ui_hi(1),ui_lo(2):ui_hi(2))
  double precision, intent(inout) :: dphidtout(uo_lo(1):uo_hi(1),uo_lo(2):uo_hi(2))
  double precision, intent(in   ) :: vx  (vx_lo(1):vx_hi(1),vx_lo(2):vx_hi(2))
  double precision, intent(in   ) :: vy  (vy_lo(1):vy_hi(1),vy_lo(2):vy_hi(2))
  double precision, intent(  out) :: flxx(fx_lo(1):fx_hi(1),fx_lo(2):fx_hi(2))
  double precision, intent(  out) :: flxy(fy_lo(1):fy_hi(1),fy_lo(2):fy_hi(2))

  integer :: i, j, numphi
  integer :: glo(2), ghi(2)
  double precision :: umax, vmax, fhi, flo, phitot

  double precision, dimension(:,:), pointer, contiguous :: &
         fluxptx, fluxpty,  phiptx, phipty,  phiavex, phiavey,  phiptcc

  glo = lo - 3
  ghi = hi + 3

  call bl_allocate(fluxptx  ,glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(fluxpty  ,glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate( phiptx  ,glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate( phipty  ,glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(phiavex  ,glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(phiavey  ,glo(1), ghi(1), glo(2), ghi(2))
  call bl_allocate(phiptcc  ,glo(1), ghi(1), glo(2), ghi(2))


  ! We like to allocate these **pointers** here and then pass them to a function
  ! to remove their pointerness for performance, because normally pointers could
  ! be aliasing.  We need to use pointers instead of allocatable arrays because
  ! we like to use BoxLib's bl_allocate to allocate memeory instead of the intrinsic
  ! allocate.  Bl_allocate is much faster than allocate inside OMP.  
  ! Note that one MUST CALL BL_DEALLOCATE.

  ! check if CFL condition is violated.
  umax = maxval(abs(vx))
  vmax = maxval(abs(vy))
  if ( umax*dt .ge. dx(1) .or. &
       vmax*dt .ge. dx(2) ) then
     print *, "umax = ", umax, ", vmax = ", vmax, ", dt = ", dt, ", dx = ", dx
     call bl_error("CFL violation. Use smaller adv.cfl.")
  end if

  ! call a function to compute flux
  call mol4thord_flux_2d(lo, hi, dt, dx, &
                         uin, ui_lo, ui_hi, &
                         vx, vx_lo, vx_hi, &
                         vy, vy_lo, vy_hi, &
                         flxx, fx_lo, fx_hi, &
                         flxy, fy_lo, fy_hi, &
                         fluxptx, phiptx, phiavex,&
                         fluxpty, phipty, phiavey,&
                         phiptcc, glo, ghi,nu,&
                         deblocell, debhicell, debloface, debhiface)

  ! Do a conservative update
  do    j = lo(2),hi(2)
     do i = lo(1),hi(1)
        !notice that some mad scientist has reversed the flux difference
        ! rather than just put a negative sign out front.
        flo = flxx(i,j)
        fhi = flxx(i+1,j)
        fhi = flxy(i,j+1)
        flo = flxy(i,j  )
        dphidtout(i,j) = &
             ( (flxx(i,j) - flxx(i+1,j  )) / dx(1) &
             + (flxy(i,j) - flxy(i  ,j+1)) / dx(2) )
     enddo
  enddo

!    numphi = 0
!    phitot = 0.0d0
!    do    j = debloface(2), debhiface(2)
!       do i = debloface(1), debhiface(1)
!          numphi = numphi + 1
!          phitot = phitot +flxy(i,j)
!!          print*, "*** i j phiave = ", i, j, phiavex(i,j), "****"
!       enddo
!    enddo
!    if(numphi .gt. 0) then
!       print*, "**************** final y flux = ", phitot/numphi
!    endif

    numphi = 0
    phitot = 0.0d0
    do    j = deblocell(2), debhicell(2)
       do i = deblocell(1), debhicell(1)
          numphi = numphi + 1
          phitot = phitot + dphidtout(i,j)
!          print*, "*** i j phiave = ", i, j, phiavex(i,j), "****"
       enddo
    enddo
    if(numphi .gt. 0) then
       print*, "**************** ndphidt, final dphidt = ", numphi, phitot/numphi
    endif
       
  ! Scale by face area in order to correctly reflux because flux register requires this
  do    j = lo(2), hi(2)
     do i = lo(1), hi(1)+1
        flxx(i,j) = flxx(i,j) * ( dt * dx(2))
     enddo
  enddo
  
  ! Scale by face area in order to correctly reflux because flux register requires this
  do    j = lo(2), hi(2)+1 
     do i = lo(1), hi(1)
        flxy(i,j) = flxy(i,j) * (dt * dx(1))
     enddo
  enddo

  call bl_deallocate(fluxptx)
  call bl_deallocate(fluxpty)
  call bl_deallocate( phiptx)
  call bl_deallocate( phipty)
  call bl_deallocate(phiavex)
  call bl_deallocate(phiavey)
  call bl_deallocate(phiptcc)

end subroutine advectDiffMOL4thOrd

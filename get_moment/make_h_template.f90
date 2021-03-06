! Saved=Fri 11 May 2018 11:31:55 AM DST
! Last Modified=Fri 11 May 2018 11:32:03 AM DST
      !This file creates H
      !The matrix is stored as CSR(A,col,rp)
      !

      !call sleep(my_id*3)
      allocate(A(NNZ),col(NNZ),rp(N+1))
      if (fixedTwist) then
          Twist = OrigTwist*pi/real(L)
      else



          allocate(TwistAll(num_procs*3*seq_rep))
          call random_number(TwistAll)
          Twist=TwistAll(my_id*3+1:my_id*3+3)
          write(*,*) 'twist:',Twist
          deallocate(TwistAll)



          Twist = (Twist)*pi/L! 0 to pi??
      endif

      expTwist = cdexp(III*Twist)

      txf = xf*cdexp(dcmplx(0d0,Twist(1)))
      txb = xb*cdexp(dcmplx(0d0,-Twist(1)))
      tyf = yf*cdexp(dcmplx(0d0,Twist(2)))
      tyb = yb*cdexp(dcmplx(0d0,-Twist(2)))
      tzf = zf*cdexp(dcmplx(0d0,Twist(3)))
      tzb = zb*cdexp(dcmplx(0d0,-Twist(3)))

      if (D.eq.2) then
          phase = 0
          if (QP) then
              Wrnd = 0d0
              WQP = W
              if (RandPhase) then
                  call random_number(phase)
              else 
                  phase = inputPhase
              endif

              phase = phase*2d0*pi
              P = 2.0d0*pi*fibonacci(fiboN-fiboM)/fibonacci(fiboN)
              Q = P
              if (commC .ne. 0) then
                  ! if set commensurate C, then Q=P=2pi/C
                  P=2.0d0*pi/commC
                  Q=P
              endif

              ! offset Q
              P = P + setQ
              Q = P


              write(*,*)"Q=" , Q,"; M=",fiboM
          else 
              WQP = 0d0
              Wrnd = W
          End if
          TQP = 0d0
          Trnd = 0d0
          t0 = 1d0
          if (RandType.eq.RandHOP) then
              WQP = 0d0
              Wrnd = 0d0
              t0 = dsqrt(1d0-W**2)
              if (QP) then
                  TQP = W
                  Trnd = 0d0
              else 
                  TQP = 0d0
                  Trnd = W
              endif
          endif


          rp = 0
          col = 0
          col_ind = 1
          rp_ind = 1
          allocate(eps(L*L)) 
          eps_ind = 1
          if (RandType.eq.RandPOT) then
              do j=1,L
              do i=1,L

              eps(eps_ind) = &
                  WQP*quasiperiodic(i+0d0,j+0d0,P,Q,phase)&
                  + Wrnd*random2D(i+0d0,j+0d0,P,Q)
              eps_ind=eps_ind+1
              enddo
              enddo
              eps = eps - sum(eps)/real(L*L)
          else if (RandType.eq.RandHOP) then
              eps = 0d0
          endif

          eps_ind = 1
          do j=1,L! y
          do i=1,L! x
          do s = 0,1
          s_ = 1-s
          ! set row pointer and disorder term
          rp(rp_ind) = 5*rp_ind-4
          col(col_ind) = rp_ind
          rp_ind = rp_ind+1
          A(col_ind) = eps(eps_ind)
          col_ind = col_ind+1

          ! x forward
          t_tmp = t0 + Trnd*random2D(i-0.5d0,j+0d0,P,Q)&
              + TQP*quasiperiodic(i-0.5d0,j+0d0,P,Q,phase)
          ind_r = xys2i(modulo(i-2,L)+1,j,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = txf(s)*t_tmp
          col_ind = col_ind+1

          ! x backward
          t_tmp = t0 + Trnd*random2D(i+0.5d0,j+0d0,P,Q)&
              + TQP*quasiperiodic(i+0.5d0,j+0d0,P,Q,phase)
          ind_r = xys2i(modulo(i,L)+1,j,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = txb(s)*t_tmp
          col_ind = col_ind+1

          ! y forward
          t_tmp = t0 + Trnd*random2D(i+0.0d0,j-0.5d0,P,Q)&
              + TQP*quasiperiodic(i+0.0d0,j-0.5d0,P,Q,phase)
          ind_r = xys2i(i,modulo(j-2,L)+1,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = tyf(s)*t_tmp
          col_ind = col_ind+1

          ! y backward
          t_tmp = t0 + Trnd*random2D(i+0.0d0,j+0.5d0,P,Q)&
              + TQP*quasiperiodic(i+0.0d0,j+0.5d0,P,Q,phase)
          ind_r = xys2i(i,modulo(j,L)+1,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = tyb(s)*t_tmp
          col_ind = col_ind+1

          End do
          eps_ind = eps_ind+1
          End do
          End do
          rp(rp_ind) = NNZ+1

          deallocate(eps)
      else if (D.eq.3) then
          ! not differentiating QP or not
          rp = 0
          col = 0
          col_ind = 1
          rp_ind = 1
          allocate(eps(L*L*L))
          eps = 0
!                call ResetRandSeed(my_id*7)
!                call random_number(eps)
!                eps = W*2.0d0*(eps-0.5d0)
!                idum=-my_id*17
          call random3D(eps,W,my_id)
!                write(*,*)eps
          eps_ind = 1
          do k=1,L!z
          do j=1,L!y 
          do i=1,L!x
          do s = 0,1
          s_ = 1-s
          ! set row pointer and disorder term
          rp(rp_ind) = 7*rp_ind-6
          col(col_ind) = rp_ind
          rp_ind = rp_ind+1
          A(col_ind) = eps(eps_ind)
          col_ind = col_ind+1

          ! x forward
          ind_r = xyzs2i(modulo(i-2,L)+1,j,k,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = txf(s)
          col_ind = col_ind+1

          ! x backward
          ind_r = xyzs2i(modulo(i,L)+1,j,k,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = txb(s)
          col_ind = col_ind+1

          ! y forward
          ind_r = xyzs2i(i,modulo(j-2,L)+1,k,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = tyf(s)
          col_ind = col_ind+1

          ! y backward
          ind_r = xyzs2i(i,modulo(j,L)+1,k,s_,L)
          col(col_ind) = ind_r
          A(col_ind) = tyb(s)
          col_ind = col_ind+1

          ! caution! z has s->s, not s->s_
          ! z forward
          ind_r = xyzs2i(i,j,modulo(k-2,L)+1,s,L)
          col(col_ind) = ind_r
          A(col_ind) = tzf(s)
          col_ind = col_ind+1

          ! z backward
          ind_r = xyzs2i(i,j,modulo(k,L)+1,s,L)
          col(col_ind) = ind_r
          A(col_ind) = tzb(s)
          col_ind = col_ind+1

          End do
          eps_ind = eps_ind + 1
          End do
          End do
          End do
          rp(rp_ind) = NNZ+1
          deallocate(eps)

      endif


! -------------------------EIGENVALUE
      include "get_eigenvalue.f90"
! --------------------EIGEnVALUE end

      ! normalization same for both

      call LanczosBound(N,NNZ,A,rp,col,1000,Emax,Emin)
      norm_a = (Emax-Emin)/(2d0-0.2d0)
      norm_b = (Emax+Emin)/2
      call rescale_to_1(N,NNZ,A,rp,col,norm_a,norm_b)



! Branched=Sun 25 Mar 2018 03:31:05 PM EDT from get_mu2d.f90
! Last Modified=Sun 25 Mar 2018 09:32:52 PM EDT
! Discontinued=Sun 25 Mar 2018 09:04:59 PM EDT
      ! currently only testing.
      ! including projection
      ! This file computes the Jxy moment

      allocate(mu2d_tot(0:Nc-1,0:Nc-1),mu2d2_tot(0:Nc-1,0:Nc-1))
      allocate(mu2d_avg(0:Nc-1,0:Nc-1),mu2d2_avg(0:Nc-1,0:Nc-1))
      allocate(mu2d(0:Nc-1,0:Nc-1))
      allocate(psi0R(N),psi0(N),psi1(N),psi_tmp(N))
      allocate(psi0_out(N),psi1_out(N),psi_tmp_out(N))
      allocate(psi_in(N),psi_p_in(N),psi_pp_in(N))
      allocate(psi_out(N),psi_p_out(N),psi_pp_out(N))
! those marked with in, multiplies J at last
      !those marked with out, multiplies J at first
!<out|in>=<0|JHHHHJHHHHH|0>

      mu2d_tot = 0
      mu2d2_tot = 0

      ! Construct projection matrix
        proj_N = N/sqrt(real(Rep))
        write(*,*)"projection space size",proj_N
        allocate(proj_psi_all(proj_N,N))
        allocate(proj_psi_all_R(proj_N,N))
        allocate(psi_r_rdc(proj_N))
        allocate(psi_l_rdc(proj_N))
        call random_number(proj_psi_all_R)
        proj_psi_all = zexp(dcmplx(0d0,2d0*pi*proj_psi_all_R))
        

      do i=1,Rep
      mu2d = 0
      
        call ResetRandSeed()
      call random_number(psi0R)
      psi0 = zexp(dcmplx(0d0,2.0d0*pi*psi0R))

      call CSRmultVc16(N,JNNZ,JA,Jrp,Jcol,psi0,psi0_out)
      
      mu2d(0,0) = dot_product(psi0_out,psi0_out)

      call CSRmultVc16(N,NNZ,A,rp,col,psi0,psi1)
      call CSRmultVc16(N,JNNZ,JA,Jrp,Jcol,psi1,psi_tmp)

      mu2d(0,1) = dot_product(psi0_out,psi_tmp)
      mu2d(1,0) = mu2d(0,1)

      call CSRmultVc16(N,NNZ,A,rp,col,psi0_out,psi1_out)
      mu2d(1,1) = dot_product(psi1_out,psi_tmp)

      psi_pp_in = psi0
      psi_p_in  = psi1
      ! now the central part: do the loops and find mu2d
        ! two ways: 1. slow; 2. fast
        ! what we need is mu2d

        if (slowOPTCOND) then
      do j=2,Nc-1
        call CSRmultVc16(N,NNZ,A,rp,col,psi_p_in,psi_tmp)
        psi_in = 2d0*psi_tmp-psi_pp_in
        call CSRmultVc16(N,JNNZ,JA,Jrp,Jcol,psi_in,psi_tmp)
        psi_pp_in = psi_p_in
        psi_p_in  = psi_in
        
        psi_pp_out = psi0_out
        mu2d(0,j) = dot_product(psi0_out,psi_tmp)
        mu2d(j,0) = mu2d(0,j)
        psi_p_out = psi1_out
        mu2d(1,j) = dot_product(psi1_out,psi_tmp)
        mu2d(j,1) = mu2d(1,j)
      do k=2,j
        call CSRmultVc16(N,NNZ,A,rp,col,psi_p_out,psi_tmp_out)
        psi_out = 2d0*psi_tmp_out-psi_pp_out
        mu2d(j,k) = dot_product(psi_out,psi_tmp)
        mu2d(k,j) = mu2d(j,k)
        psi_pp_out = psi_p_out
        psi_p_out  = psi_out
      End do
      enddo

        else 
                ! here is the fast way (takes more memory)
                ! first: construct all psi and save
                ! then: find the expectation one by one.
                allocate(psi_all_out(0:Nc-1,N))
                psi_pp_out = psi0_out
                psi_p_out = psi1_out
                psi_all_out(0,:) = psi_pp_out
                psi_all_out(1,:) = psi_p_out

                
      do j=2,Nc-1
        call CSRmultVc16(N,NNZ,A,rp,col,psi_p_in,psi_tmp)
        psi_in = 2d0*psi_tmp-psi_pp_in
        call CSRmultVc16(N,JNNZ,JA,Jrp,Jcol,psi_in,psi_tmp)
        psi_pp_in = psi_p_in
        psi_p_in  = psi_in
        
        call CSRmultVc16(N,NNZ,A,rp,col,psi_p_out,psi_tmp_out)
        psi_out = 2d0*psi_tmp_out-psi_pp_out
        psi_pp_out = psi_p_out
        psi_p_out  = psi_out
        psi_all_out(j,:) = psi_out

        psi_r_rdc = MATMUL(proj_psi_all,psi_tmp)
      do k=0,j
        psi_l_rdc = MATMUL(proj_psi_all,psi_all_out(k,:))
        mu2d(j,k) = dot_product(psi_l_rdc,psi_r_rdc)/proj_N
        mu2d(k,j) = mu2d(j,k)
      End do
        write(*,*)'step',j
      enddo

        deallocate(psi_all_out)



        endif

        mu2d_tot = mu2d_tot + mu2d
        mu2d2_tot = mu2d2_tot + mu2d*mu2d
      enddo
      mu2d_avg = mu2d_tot/(Rep*N)
      mu2d2_avg = mu2d2_tot/(Rep*N)
      deallocate(mu2d_tot,mu2d2_tot,mu2d)
      deallocate(psi0R,psi0,psi1,psi_tmp)
      deallocate(psi0_out,psi1_out,psi_tmp_out)
      deallocate(psi_in,psi_p_in,psi_pp_in)
      deallocate(psi_out,psi_p_out,psi_pp_out)
      deallocate(proj_psi_all,proj_psi_all_R)
      deallocate(psi_r_rdc,psi_l_rdc)
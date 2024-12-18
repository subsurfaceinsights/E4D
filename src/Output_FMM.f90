module output_fmm
  
  use fmm_vars
  use report_fmm

  integer, dimension(:,:), allocatable :: itt

contains
  !_______________________________________________________________________________________
  ! output observed and predicted traveltime at measurement point
  subroutine output_ttpred
    implicit none
    
    integer :: ttp_flag, ist
    integer :: i
    logical :: exst
    character*80 :: fname,ttp_file
 
    inquire(file=trim(outfile_fmm),exist=exst); if(.not.exst) goto 10
    open(15,file=trim(outfile_fmm),status='old',action='read')
    read(15,*,IOSTAT=ist) ttp_flag;  if(ist.ne.0) goto 11
    read(15,*,IOSTAT=ist) ttp_file; if(ist.ne.0) goto 12
    close(15)
    
    if(ttp_flag==1) then

       open(15,file=ttp_file,status='replace',action='write')
       write(15,*) nm_fmm
       do i=1,nm_fmm
             write(15,1001) i,s_conf_fmm(i,1:2),dobs_fmm(i),ttpred(i)
       end do
       close(15)
    end if
    return

10  continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 'Cannot find the output options file: ',trim(outfile_fmm)
      close(51)
      write(*,*) 'Cannot find the output options file: ',trim(outfile_fmm)
      return
      
11    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 'The was a problem reading the first line in the output file: ',trim(outfile_fmm)
      write(51,*) 'aborting'
      close(51)
      write(*,*) 'The was a problem reading the first line in the output file: ',trim(outfile_fmm)
      write(*,*) 'aborting'
      return

12    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 'The was a problem reading the predicted data file in: ',trim(outfile_fmm)
      write(51,*) 'aborting'
      close(51)
      write(*,*) 'The was a problem reading the predicted data file in: ',trim(outfile_fmm)
      write(*,*) 'aborting'
      return

13    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 'The was a problem reading the number of travel time fields to write in: ',trim(outfile_fmm)
      write(51,*) 'aborting'
      close(51)
      write(*,*) 'The was a problem reading the number of travel time fields to write in: ',trim(outfile_fmm)
      write(*,*) 'aborting'
      return

14    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 'The was a problem reading travel time index: ',i,' in: ',trim(outfile_fmm)
      write(51,*) 'aborting'
      close(51)
      write(*,*) 'The was a problem reading travel time index: ',i,' in: ',trim(outfile_fmm)
      write(*,*) 'aborting'

      return

   
1001 format(1I8,2I8,2g15.6)

  end subroutine output_ttpred
  !_______________________________________________________________________________________
  !_______________________________________________________________________________________
  subroutine fmm_build_srv
    implicit none
    character*80 :: fname=""
    integer :: i

    write(fname,"(A,A)") trim(spdfile),'.srv'
    call nreport_fmm(69)
    open(12,file=fname,status='replace',action='write')
    if(.not.fresnel) then
       write(12,*) ns,' 0'
       do i=1,ns
          write(12,"(I10,3F15.5)") i,s_pos(i,1)+xorig,s_pos(i,2)+yorig,s_pos(i,3)+zorig
       end do
       write(12,*)
       
       write(12,*) nrc
       do i=1,nrc
          write(12,"(I10,3F15.5)") i,rc_pos(i,1)+xorig,rc_pos(i,2)+yorig,rc_pos(i,3)+zorig
       end do
    else
       write(12,*) ns,' 1'
       do i=1,ns
          write(12,"(I10,4F15.5)") i,s_pos(i,1)+xorig,s_pos(i,2)+yorig,s_pos(i,3)+zorig,frq(i)
       end do
    end if
    write(12,*) 
    
    write(12,*) nm_fmm

    do i=1,nm_fmm
       write(12,"(I8,2I10,2G15.5)") i,s_conf_fmm(i,1:2),ttpred(i),0.05*abs(ttpred(i))+0.01
    end do
    close(12)
    
  end subroutine fmm_build_srv

  !_______________________________________________________________________________________
  subroutine write_tt
    implicit none
    integer :: ttp_flag,ntt,o_opt,ist
    logical :: fcheck
    character*80 :: ttp_file
    character*20 :: fname
    integer :: i,a,j,smin,smax,ra
    integer, dimension(2) :: spack
    real, dimension(nnodes) :: pa
    integer ::  status(MPI_STATUS_SIZE)

   
    inquire(file=trim(outfile_fmm),exist=fcheck); if(.not.fcheck) goto 10
  
    call nreport_fmm(21)
    open(15,file=outfile_fmm,status='old',action='read')
    read(15,*,IOSTAT=ist) ttp_flag; if(ist.ne.0) goto 11
    read(15,*,IOSTAT=ist) ttp_file; if(ist.ne.0) goto 12
    read(15,*,IOSTAT=ist) ntt   ; if(ist.ne.0) goto 13

    if(ntt>0) then
! why 2d itt?
       allocate(itt(ntt,2))
       do i=1,ntt
          read(15,*,IOSTAT=ist) itt(i,1); if(ist.ne.0) goto 14
       end do
    end if
  
    do i=1,ntt
       pa=0
       if(itt(i,1)>ns) goto 100
!       a=s_conf_fmm(itt(i,1),1)
       a = itt(i,1)
       do j=1,n_rank_fmm-1
          smin=sind(j,1); smax=sind(j,2)
          if((smin .le. a) .and. (smax .ge. a)) ra = j	
       end do
    
       if(a .ne. 0) then
          spack(1) = ra
          spack(2) = a
          call send_commando_fmm(23)
          call MPI_BCAST(spack,2,MPI_INTEGER,0,FMM_COMM,ierr)
          call MPI_RECV(pa,nnodes,MPI_REAL,ra,0,FMM_COMM,status,ierr)
       end if
       
       
       write(fname,"(A,I0)") "traveltime.",itt(i,1)
       open(27,file=fname,status='replace',action='write')
       write(27,*) nnodes, 1, itt(i,1)
       do j=1,nnodes
          write(27,*) pa(j)
       end do
       close(27)

       
100    continue
    end do
    return

   
10  continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 
      write(51,*) ' Cannot find the output options file: ',trim(outfile_fmm)
      close(51)
      write(*,*) 
      write(*,*) ' Cannot find the output options file: ',trim(outfile_fmm)
      return
      
11    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 
      write(51,*) ' The was a problem reading the first line in the output file: ',trim(outfile_fmm)
      close(51)
      write(*,*) 
      write(*,*) ' There was a problem reading the first line in the output file: ',trim(outfile_fmm)
      return

12    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 
      write(51,*) 'There was a problem reading the predicted data file name in: ',trim(outfile_fmm)
      close(51)
      write(*,*) 
      write(*,*) 'The was a problem reading the predicted data file in: ',trim(outfile_fmm)
      return

13    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) 
      write(51,*) ' There was a problem reading the number of travel time fields to write in: ',trim(outfile_fmm)
      close(51)
      write(*,*) 
      write(*,*) ' There was a problem reading the number of travel time fields to write in: ',trim(outfile_fmm)
      return

14    continue
      open(51,file='fmm.log',status='old',action='write',position='append')
      write(51,*) ' There was a problem reading travel time field index: ',i,' in: ',trim(outfile_fmm)
      close(51)
      write(*,*)
      write(*,*) ' There was a problem reading travel time field index: ',i,' in: ',trim(outfile_fmm)
      return

  end subroutine write_tt

  !_____________________________________________________________________
  subroutine send_commando_fmm(com)
    !!Send a general command to the slaves
    integer :: com
    
    call MPI_BCAST(com,1,MPI_INTEGER,0,FMM_COMM,ierr)
    
  end subroutine send_commando_fmm
  !____________________________________________________________________
  
  !_______________________________________________________________________________________
  subroutine write_speed
    implicit none
    integer :: i
    character(20) :: fname=""
    
    write(fname,"(A,I0)") "speed.",iter
    open(12,file=fname,status='replace',action='write')
    write(12,*) nelem," 1"
    do i=1,nelem
          write(12,*) sqrt(1/speed(i))
    end do
    
    close(12)
  end subroutine write_speed
  !_______________________________________________________________________________________
 
 
end module output_fmm
 

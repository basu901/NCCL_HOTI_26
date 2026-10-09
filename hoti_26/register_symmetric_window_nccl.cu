#include<stdlib.h>
#include<cuda_runtime.h>
#include <nccl.h>
#include<mpi.h>

#define NCCL_CHECK(stmt) do{ \
    ncclResult_t status = stmt; \
    if(status!=ncclSuccess){    \
        fprintf(stderr,"Failed to perform NCCL operation: %s, in %s:%d. Failed with %s:%d\n", \
        stmt, __FILE__,__LINE__,ncclGetErrorString(stmt),status); \
    }                           \
}while(0)

#define CUDA_CHECK(stmt) do{ \
    cudaError_t status = stmt; \
    if(status!=cudaSuccess){ \
        fprintf(stderr,"Failed to perform CUDA Operation:%s in %s:%d\n. Failed with %s:%d\n", \
            stmt, __FILE__, __LINE__,cudaGetErrorString(stmt),status); \
    } \
}while(0)


int main(int argc, char** argv){
    MPI_Init(&argc, &argv);
    MPI_Comm local_comm;
    int size, rank, local_rank, device_count;
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, rank, MPI_INFO_NULL, &local_comm);
    MPI_Comm_rank(local_comm, &local_rank);
    MPI_Comm_free(&local_comm);

    cudaGetDeviceCount(&device_count);
    if(device_count==0 || (device_count!=1 && device_count<=local_rank)){
        fprintf(stderr, "Rank:%d -> Not enough devices. Found %d devices\n", rank, device_count);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    device_count==1?cudaSetDevice(0):cudaSetDevice(local_rank);

    void *src, *dest;
    ncclWindow_t src_win, dest_win;
    int* d_dest;
    int* h_send = (int*)malloc(sizeof(int));
    int* h_dest = (int*)malloc(sizeof(int)*size);

    ncclUniqueId id;
    ncclComm_t nccl_comm;
    if(rank==0)
        ncclGetUniqueId(&id);

    MPI_Bcast(&id, sizeof(id), MPI_BYTE, 0, MPI_COMM_WORLD);
    ncclCommInitRank(&nccl_comm, size, id, rank);


    NCCL_CHECK(ncclMemAlloc(&src, sizeof(int)));
    NCCL_CHECK(ncclMemAlloc(&dest, sizeof(int)*size));

    ncclCommWindowRegister(nccl_comm,src,sizeof(int),&src_win,NCCL_WIN_COLL_SYMMETRIC);
    ncclCommWindowRegister(nccl_comm,dest,sizeof(int)*size,&dest_win,NCCL_WIN_COLL_SYMMETRIC);

    cudaStream_t stream;
    cudaStreamCreate(&stream);

    *h_send = rank+1;

    CUDA_CHECK(cudaMemcpyAsync(src,h_send,sizeof(int),cudaMemcpyHostToDevice,stream));
    cudaStreamSynchronize(stream);

    NCCL_CHECK(ncclAllGather((char*)src,(char*)dest,sizeof(int),ncclInt8,nccl_comm,stream));
    CUDA_CHECK(cudaStreamSynchronize(stream));

    CUDA_CHECK(cudaMemcpyAsync(h_dest,dest,sizeof(int)*size,cudaMemcpyDeviceToHost,stream));
    cudaStreamSynchronize(stream);

    printf("\nRank %d:",rank);
    for(int i=0;i<size;i++){
      printf("%d ",h_dest[i]);
     }

    printf("\n");
    NCCL_CHECK(ncclCommWindowDeregister(nccl_comm,src_win));
    NCCL_CHECK(ncclCommWindowDeregister(nccl_comm,dest_win));
    NCCL_CHECK(ncclMemFree(src));
    NCCL_CHECK(ncclMemFree(dest));
    NCCL_CHECK(ncclCommDestroy(nccl_comm));
    CUDA_CHECK(cudaFree(d_dest));
    CUDA_CHECK(cudaStreamDestroy(stream));
    free(h_dest);
    MPI_Finalize();
    return 0;
}
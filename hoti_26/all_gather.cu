#include<cuda_runtime.h>
#include<mpi.h>
#include<stdio.h>
#include<nccl.h>
#include<stdlib.h>

#define NCCL_CHECK(stmt)                                                        \
do{                                                                             \
    ncclResult_t status = stmt;                                                 \
    if(status!=ncclSuccess){                                                    \
        fprintf(stderr,"OP:%s failed in %s:%d with error:\n%s:%d\n",                                                            \
            stmt, __FILE__, __LINE__, ncclGetErrorString(stmt), status);        \
        MPI_Abort(MPI_COMM_WORLD, status);                                      \
    }                                                                           \
}while(0)               


#define CUDA_CHECK(stmt)                                                        \
do{                                                                             \
    cudaError_t status = stmt;                                                  \
    if(status!=cudaSuccess){                                                    \
        fprintf(stderr,"OP:%s failed in %s:%d with error:\n%s:%d\n",                                                    \
        stmt, __FILE__, __LINE__, cudaGetErrorString(stmt), status);            \
        MPI_Abort(MPI_COMM_WORLD, status);                                      \
    }                                                                           \
}while(0)


int main(int argc,char** argv){
    MPI_Init(&argc,&argv);

    int size, rank, local_rank, device_count;
    MPI_Comm local_comm;

    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    CUDA_CHECK(cudaGetDeviceCount(&device_count));
    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, rank,  MPI_INFO_NULL, &local_comm);

    MPI_Comm_rank(local_comm, &local_rank);
    MPI_Comm_free(&local_comm);

    if(device_count==0 || (device_count!=1 && device_count<=local_rank)){
        fprintf(stderr, "Not enough GPUs: Rank %d", local_rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
        exit(1);
    }

    CUDA_CHECK(cudaSetDevice(device_count==1?0:local_rank));

    ncclUniqueId id;
    ncclComm_t nccl_comm;

    if(rank==0)
        NCCL_CHECK(ncclGetUniqueId(&id));

    MPI_Bcast(&id, sizeof(id), MPI_BYTE, 0, MPI_COMM_WORLD);
    NCCL_CHECK(ncclCommInitRank(&nccl_comm, size, id, rank));

    int *h_data_send, *h_data_recv;
    int *d_data_send, *d_data_recv;

    cudaStream_t stream;
    h_data_send = (int*)malloc(sizeof(int));
    h_data_recv = (int*)malloc(sizeof(int));

    printf("Rank:%d, created NCCL comm and host mem\n",rank);
    CUDA_CHECK(cudaMalloc((void **)&d_data_send,sizeof(int)));
    CUDA_CHECK(cudaMalloc((void **)&d_data_recv, sizeof(int)*size));

     *h_data_send = rank+1;
    CUDA_CHECK(cudaStreamCreate(&stream));
    CUDA_CHECK(cudaMemcpyAsync(d_data_send, h_data_send, sizeof(int), cudaMemcpyHostToDevice, stream));
    NCCL_CHECK(ncclAllGather(d_data_send, d_data_recv, sizeof(int), ncclInt8, nccl_comm, stream));

    CUDA_CHECK(cudaMemcpyAsync(h_data_recv,d_data_recv, sizeof(int)*size, cudaMemcpyDeviceToHost, stream));
    int val = (size *(size+1))/2;
    int count = 0;
    for(int i=0;i<size;i++)
        count += h_data_recv[i];
    printf("Rank %d, Count=%d , Value=%d\n",rank,count,val);

    CUDA_CHECK(cudaFree(d_data_send));
    CUDA_CHECK(cudaFree(d_data_recv));
    CUDA_CHECK(cudaStreamDestroy(stream));
    NCCL_CHECK(ncclCommDestroy(nccl_comm));
    MPI_Finalize();
    free(h_data_recv);
    return 0;

}
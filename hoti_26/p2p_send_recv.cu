#include<cuda_runtime.h>
#include<mpi.h>
#include<stdio.h>
#include<stdlib.h>
#include<nccl.h>

#define ncclCheck(stmt)                                                 \
do{                                                                     \
    ncclResult_t status = stmt;                                         \
    if(status!=ncclSuccess){                                            \
        fprintf(stderr, "NCCL OP:%s in %s:%d, failed with %s:%d\n.",    \
        stmt, __FILE__, __LINE__, ncclGetErrorString(stmt), status);    \
        MPI_Abort(MPI_COMM_WORLD, status);                              \
    }                                                                   \
}while(0)

#define cudaCheck(stmt)                                                 \
do{                                                                     \
    cudaError_t status = stmt;                                          \
    if(status!=cudaSuccess){                                            \
        fprintf(stderr, "CUDA OP: %s in %s:%d, failed with %s:%d\n.",   \
        stmt, __FILE__, __LINE__, cudaGetErrorString(stmt), status);    \
        MPI_Abort(MPI_COMM_WORLD, status);                              \
    }                                                                   \
}while(0)                                                               \

#define N 10


void setHostData(int *h_data){
    for(int i=0;i<N;i++)
        h_data[i]=i;
}

void printData(int* d, int rank){
    printf("Rank:%d\n",rank);
    for(int i=0;i<N;i++)
      printf("%d ",*(d+i));
    printf("\n");
}

int main(int argc, char** argv){

    MPI_Init(&argc, &argv);
    int rank, local_rank, size;
    MPI_Comm local_comm;
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, rank, MPI_INFO_NULL, &local_comm);
    MPI_Comm_rank(local_comm, &local_rank);
    MPI_Comm_free(&local_comm);
    int device_count;
    cudaCheck(cudaGetDeviceCount(&device_count));


    if(device_count==0|| (device_count!=1 && device_count<=local_rank)){
        fprintf(stderr, "Not enough devices. Found %d devices. Missing device for %d\n", device_count,local_rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    cudaCheck(cudaSetDevice(device_count==1?0:local_rank));

    ncclUniqueId nccl_id;
    ncclComm_t nccl_comm;

    if(rank==0)
        ncclCheck(ncclGetUniqueId(&nccl_id));

    MPI_Bcast(&nccl_id, sizeof(nccl_id), MPI_BYTE, 0, MPI_COMM_WORLD);
    ncclCheck(ncclCommInitRank(&nccl_comm, size, nccl_id, rank));

    printf("Rank:%d, Assigned nccl ID\n",rank);

    int *h_data_send, *h_data_recv;
    int *d_data_send, *d_data_recv;
    int error;

    cudaMalloc((void**)&d_data_recv, sizeof(int)*N);
    cudaMalloc((void**)&d_data_send, sizeof(int)*N);

    h_data_send=(int*)malloc(sizeof(int)*N);
    h_data_recv=(int*)malloc(sizeof(int)*N);

    cudaStream_t stream;
    cudaCheck(cudaStreamCreate(&stream));
    if(rank==0){
        printf("Rank %d about to send:\n",rank);
        setHostData(h_data_send);
        cudaMemcpyAsync(d_data_send,h_data_send,sizeof(int)*N,cudaMemcpyHostToDevice,stream);
        ncclSend(d_data_send,N*sizeof(int),ncclInt8,rank+1,nccl_comm,stream);
    }
    else{
        ncclRecv(d_data_recv,N*sizeof(int),ncclInt8,rank-1,nccl_comm,stream);
        if(rank!=size-1)
                ncclSend(d_data_recv,N*sizeof(int),ncclInt8,rank+1,nccl_comm,stream);
        cudaMemcpyAsync(h_data_recv,d_data_recv,sizeof(int)*N,cudaMemcpyDeviceToHost,stream);
        cudaStreamSynchronize(stream);
        printData(h_data_recv,rank);
        for(int i=0;i<N;i++){
            if(h_data_recv[i]!=i)
                error++;
        }
        printf("Found %d errors for rank %d\n", error, rank);
    }

    cudaCheck(cudaFree(d_data_send));
    cudaCheck(cudaFree(d_data_recv));
    ncclCheck(ncclCommDestroy(nccl_comm));
    cudaCheck(cudaStreamDestroy(stream));
    free(h_data_send);
    free(h_data_recv);
    MPI_Finalize();

    return 0;

}
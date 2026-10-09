NP ?= 6
NVCC ?= nvcc
MPICXX ?= mpicxx
MPIRUN ?= mpirun
NCCL_HOME ?= /usr/local/nccl
JSC_SUBMIT_CMD ?= $(MPIRUN)
LAUNCHER ?= $(JSC_SUBMIT_CMD) -n $(NP)
CUDA_HOME ?= /usr/local/cuda
CUDA_VISIBLE_DEVICES ?=
CUDA_ARCH ?= 75
RUN_ENV = $(if $(strip $(CUDA_VISIBLE_DEVICES)),CUDA_VISIBLE_DEVICES=$(CUDA_VISIBLE_DEVICES))
NVCCFLAGS += -O2 -std=c++17 -gencode arch=compute_$(CUDA_ARCH),code=sm_$(CUDA_ARCH)
CPPFLAGS += -I$(CUDA_HOME)/include -I$(NCCL_HOME)/include
LDFLAGS += -L$(CUDA_HOME)/lib64 -L$(NCCL_HOME)/lib
LDLIBS += -lcudart -lnccl

BIN := default

.PHONY: all clean run

all: $(BIN)

$(BIN): mpi_cuda_p2p_send_recv.cu
        $(NVCC) -ccbin $(MPICXX) -std=c++14 $(CPPFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@

p2p_send_recv: mpi_cuda_p2p_send_recv.cu
        $(NVCC) -ccbin $(MPICXX) -std=c++14 $(CPPFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@

allgather: mpi_cuda_allgather.cu
        $(NVCC) -ccbin $(MPICXX) -std=c++14 $(CPPFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@

register_symmetric_window: register_symmetric_window.cu
        $(NVCC) -ccbin $(MPICXX) -std=c++14 $(CPPFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@

symmetric_window_putsignal: symmetric_window_putsignal.cu
        $(NVCC) -ccbin $(MPICXX) $(NVCCFLAGS) $(CPPFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@

run: $(BIN)
        $(RUN_ENV) $(LAUNCHER) ./$(BIN)

clean:
        rm -f $(BIN)
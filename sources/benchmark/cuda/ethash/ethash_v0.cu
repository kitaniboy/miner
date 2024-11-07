///////////////////////////////////////////////////////////////////////////////
#include <benchmark/cuda/kernels.hpp>

///////////////////////////////////////////////////////////////////////////////
#include <benchmark/cuda/common/common.cuh>

///////////////////////////////////////////////////////////////////////////////
__constant__ uint4* d_dag;
__constant__ uint4 d_header[2];
__constant__ uint64_t d_boundary;
__constant__ uint32_t d_dag_number_item;

///////////////////////////////////////////////////////////////////////////////
#include <benchmark/cuda/ethash/ethash_keccak_f1600.cuh>

//////////////////////////////////////////////////j/////////////////////////////
#define _PARALLEL_HASH 4
#define ACCESSES 64
#define THREADS_PER_HASH (128 / 16)


///////////////////////////////////////////////////////////////////////////////
union
{
    uint32_t words[128 / sizeof(uint32_t)];
    uint2    uint2s[128 / sizeof(uint2)];
    uint4    uint4s[128 / sizeof(uint4)];
} hash128_t;


__device__ __forceinline__
uint64_t cuda_swab64(const uint64_t x)
{
    uint64_t result;
    uint2 t;
    asm volatile(
        "mov.b64 {%0,%1},%2; \n\t"
        : "=r"(t.x), "=r"(t.y)
        : "l"(x));
    t.x = __byte_perm(t.x, 0, 0x0123);
    t.y = __byte_perm(t.y, 0, 0x0123);
    asm volatile(
        "mov.b64 %0,{%1,%2}; \n\t"
        : "=l"(result) : "r"(t.y), "r"(t.x));
    return result;
}


__global__
void kernel_ethash_v0(
    volatile t_result_64* result,
    uint64_t const startNonce)
{
    uint2 state[12];
    uint2 mix_hash[4];

    uint32_t const gid{ (blockIdx.x * blockDim.x) + threadIdx.x };
    int const thread_id = threadIdx.x & (THREADS_PER_HASH - 1);
    int const mix_idx = thread_id & 3;
    uint64_t const nonce = startNonce + gid;

    state[4] = vectorize(nonce);
    ethash_keccak_f1600_init(state);

    for (int i = 0; i < THREADS_PER_HASH; i += _PARALLEL_HASH)
    {
        uint4 mix[_PARALLEL_HASH];
        uint32_t offset[_PARALLEL_HASH];
        uint32_t init0[_PARALLEL_HASH];

        for (int p = 0; p < _PARALLEL_HASH; p++)
        {
            uint2 shuffle[8];
            for (int j = 0; j < 8; j++)
            {
                shuffle[j].x = reg_load(state[j].x, i + p, THREADS_PER_HASH);
                shuffle[j].y = reg_load(state[j].y, i + p, THREADS_PER_HASH);
            }

            switch (mix_idx)
            {
            case 0:
                mix[p] = vectorize_u2(shuffle[0], shuffle[1]);
                break;
            case 1:
                mix[p] = vectorize_u2(shuffle[2], shuffle[3]);
                break;
            case 2:
                mix[p] = vectorize_u2(shuffle[4], shuffle[5]);
                break;
            case 3:
                mix[p] = vectorize_u2(shuffle[6], shuffle[7]);
                break;
            }

            init0[p] = reg_load(shuffle[0].x, 0, THREADS_PER_HASH);
        }

        for (uint32_t a = 0; a < ACCESSES; a += 4)
        {
            int t = bfe(a, 2u, 3u);

            for (uint32_t b = 0; b < 4; b++)
            {
                for (int p = 0; p < _PARALLEL_HASH; p++)
                {
                    offset[p] = fnv1(
                        init0[p] ^ (a + b),
                        ((uint32_t*)&mix[p])[b]) % d_dag_number_item;
                    offset[p] = reg_load(offset[p], t, THREADS_PER_HASH);
                    uint32_t start_index = offset[p];
                    fnv1(&mix[p], &d_dag[start_index * 8  + thread_id])
                }
            }
        }

        for (int p = 0; p < _PARALLEL_HASH; p++)
        {
            uint2 shuffle[4];
            uint32_t thread_mix = fnv1_reduce(mix[p]);

            shuffle[0].x = reg_load(thread_mix, 0, THREADS_PER_HASH);
            shuffle[0].y = reg_load(thread_mix, 1, THREADS_PER_HASH);
            shuffle[1].x = reg_load(thread_mix, 2, THREADS_PER_HASH);
            shuffle[1].y = reg_load(thread_mix, 3, THREADS_PER_HASH);
            shuffle[2].x = reg_load(thread_mix, 4, THREADS_PER_HASH);
            shuffle[2].y = reg_load(thread_mix, 5, THREADS_PER_HASH);
            shuffle[3].x = reg_load(thread_mix, 6, THREADS_PER_HASH);
            shuffle[3].y = reg_load(thread_mix, 7, THREADS_PER_HASH);

            if ((i + p) == thread_id)
            {
                state[8] = shuffle[0];
                state[9] = shuffle[1];
                state[10] = shuffle[2];
                state[11] = shuffle[3];
            }
        }
    }

    uint64_t final_state = ethash_keccak_f1600_final(state);
 
    if (cuda_swab64(final_state) > d_boundary)
    {
        uint32_t index = atomicAdd((uint32_t*)&result->index, 1);
        if (index >= 4)
            return;
        result->found = true;
        result->nonce[index] = gid;
        result->mix[index][0] = 0;
        result->mix[index][1] = 1;
        result->mix[index][2] = 2;
        result->mix[index][3] = 3;
    }
}


__host__
bool init_ethash_v0(
    std::string const header)
{
    // cudaError_t error{ cudaSuccess };

    // uint4 const* header{ (uint4 const*)&kp.header_local };
    // error = cudaMemcpyToSymbol(d_header, header, sizeof(uint4) * 2);
    // if (error != cudaSuccess)
    // {
    //     printf("d_header: %s\n", cudaGetErrorString(error));
    //     return false;
    // }

    // error = cudaMemcpyToSymbol(d_boundary, (void*)&kp.boundary, sizeof(uint64_t));
    // if (error != cudaSuccess)
    // {
    //     printf("d_boundary: %s\n", cudaGetErrorString(error));
    //     return false;
    // }

    // error = cudaMemcpyToSymbol(d_dag_number_item, (void*)&kp.dagNumberItem, sizeof(uint32_t));
    // if (error != cudaSuccess)
    // {
    //     printf("d_dag_number_item: %s\n", cudaGetErrorString(error));
    //     return false;
    // }

    // uint4 const* dag{ (uint4 const*)kp.dagHash };
    // error = cudaMemcpyToSymbol(d_dag, &dag, sizeof(uint4*));
    // if (error != cudaSuccess)
    // {
    //     printf("d_dag: %s\n", cudaGetErrorString(error));
    //     return false;
    // }

    return true;
}

__host__
bool ethash_v0(
        cudaStream_t stream,
        uint32_t const blocks,
        uint32_t const threads)
{
    t_result_64 result{};

    kernel_ethash_v0<<<blocks, threads, 0, stream>>>(
        &result,
        0x3835000000000000ull);
    CUDA_ER(cudaStreamSynchronize(stream));
    CUDA_ER(cudaGetLastError());

    return true;
}

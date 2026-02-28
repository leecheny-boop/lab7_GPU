#include <cuda_bf16.h>
#include <stdint.h>

// 1. vector addition (interger int16_t)
__global__ void int16_vector_add(int16_t *a, int16_t *b, int16_t *c) {
    int idx = threadIdx.x;
    c[idx] = a[idx] + b[idx];
}

// 2. vector subtraction (interger int16_t)
__global__ void int16_vector_sub(int16_t *a, int16_t *b, int16_t *c) {
    int idx = threadIdx.x;
    c[idx] = a[idx] - b[idx];
}

// 3. BFloat16 vector multiply
__global__ void bf16_vector_mul(__nv_bfloat16 *a, __nv_bfloat16 *b, __nv_bfloat16 *c) {
    int idx = threadIdx.x;
    c[idx] = __hmul(a[idx], b[idx]);
}

// 4. BFloat16 fused multiply-accumulate (MAC)
__global__ void bf16_fma(__nv_bfloat16 *a, __nv_bfloat16 *b, __nv_bfloat16 *c, __nv_bfloat16 *d) {
    int idx = threadIdx.x;
    d[idx] = __hfma(a[idx], b[idx], c[idx]);
}

// 5. ReLU Activation
__global__ void int16_relu(int16_t *in, int16_t *out) {
    int idx = threadIdx.x;
    // if in[idx] is larger than 0，then output in[idx]，otherwise output 0
    out[idx] = in[idx] > 0 ? in[idx] : 0;
}

#ifndef MUNI_AGD_RUNTIME_H
#define MUNI_AGD_RUNTIME_H
#include <stddef.h>
typedef struct AGDPlan AGDPlan;
size_t agd_quotient_size(size_t d,size_t tile);
int agd_validate_block_constant(const double*x,size_t d,size_t tile,double tol);
double agd_max_abs_error(const double*a,const double*b,size_t n);
int agd_full_apply(const double*x,double*y,size_t d,size_t tile,const double*w,size_t nw);
int agd_quotient_apply(const double*q,double*y,size_t r,const double*w,size_t nw);
int agd_reconstruct(const double*q,double*x,size_t d,size_t tile);
AGDPlan* agd_plan_create(const double*x,size_t d,size_t tile,const double*w,size_t nw,double tol);
int agd_plan_step(AGDPlan*p);
int agd_plan_run(AGDPlan*p,size_t steps);
int agd_plan_reconstruct(AGDPlan*p,double*out);
size_t agd_plan_size(const AGDPlan*p);
void agd_plan_destroy(AGDPlan*p);
#endif

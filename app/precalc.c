#include "precalc.h"

bool vert_sort(Vert* va, Vert* vb, Vert* vc, Vert** v1, Vert** v2, Vert** v3)
{
    if (va->x == vb->x && va->x == vc->x){
        return false;
    } else if (va->x < vb->x && va->x < vc->x && vb->x < vc->x){
        *v1 = va;
        *v2 = vb;
        *v3 = vc;
    } else if (va->x < vb->x && va->x < vc->x && vb->x >= vc->x){
        *v1 = va;
        *v2 = vc;
        *v3 = vb;
    } else if (va->x >= vb->x && va->x < vc->x && vb->x < vc->x){
        *v1 = vb;
        *v2 = va;
        *v3 = vc;
    } else if (va->x < vb->x && va->x >= vc->x && vb->x >= vc->x){
        *v1 = vc;
        *v2 = va;
        *v3 = vb;
    } else if (va->x >= vb->x && va->x >= vc->x && vb->x < vc->x){
        *v1 = vb;
        *v2 = vc;
        *v3 = va;
    } else if (va->x >= vb->x && va->x >= vc->x && vb->x >= vc->x){
        *v1 = vc;
        *v2 = vb;
        *v3 = va;
    } else {
        return false;
    }
    return true;
}

bool precalc_triangle(Vert* v1, Vert* v2, Vert* v3, TriangleBlock *t){
    /*Vert* v1;
    Vert* v2;
    Vert* v3;
    if (va->x == vb->x && va->x == vc->x){
        return false;
    } else if (va->x < vb->x && va->x < vc->x && vb->x < vc->x){
        v1 = va;
        v2 = vb;
        v3 = vc;
    } else if (va->x < vb->x && va->x < vc->x && vb->x >= vc->x){
        v1 = va;
        v2 = vc;
        v3 = vb;
    } else if (va->x >= vb->x && va->x < vc->x && vb->x < vc->x){
        v1 = vb;
        v2 = va;
        v3 = vc;
    } else if (va->x < vb->x && va->x >= vc->x && vb->x >= vc->x){
        v1 = vc;
        v2 = va;
        v3 = vb;
    } else if (va->x >= vb->x && va->x >= vc->x && vb->x < vc->x){
        v1 = vb;
        v2 = vc;
        v3 = va;
    } else if (va->x >= vb->x && va->x >= vc->x && vb->x >= vc->x){
        v1 = vc;
        v2 = vb;
        v3 = va;
    } else {
        return false;
    }*/

    float _dx = 1.0f/(v3->x-v1->x);

    float Q = (v2->x-v1->x) * _dx;
    float mz = (v3->z-v1->z) * _dx;
    float mr = (v3->r-v1->r) * _dx;
    float mg = (v3->g-v1->g) * _dx;
    float mb = (v3->b-v1->b) * _dx;
    //float mu = (v3->u-v1->u) * _dx;
    //float mv = (v3->v-v1->v) * _dx;
    float m1 = (v3->y-v1->y) * _dx;
    float m2;
    if (v2->x == v1->x)
        m2 = 0.0f;
    else
        m2 = (v2->y-v1->y)/(v2->x-v1->x);
    float m3;
    if (v3->x == v2->x)
        m3 = 0.0f;
    else
        m3 = (v3->y-v2->y)/(v3->x-v2->x);
    
    if((v2->y-v1->y-Q*(v3->y-v1->y)) == 0)
        return false;

    float _dQ = 1.0f / (v2->y-v1->y-Q*(v3->y-v1->y));
    float nz = (v2->z-v1->z-Q*(v3->z-v1->z)) * _dQ;
    float nr = (v2->r-v1->r-Q*(v3->r-v1->r)) * _dQ;
    float ng = (v2->g-v1->g-Q*(v3->g-v1->g)) * _dQ;
    float nb = (v2->b-v1->b-Q*(v3->b-v1->b)) * _dQ;
    //float nu = (v2->u-v1->u-Q*(v3->u-v1->u)) * _dQ;
    //float nv = (v2->v-v1->v-Q*(v3->v-v1->v)) * _dQ;

    float y_end;
    if (v2->x == v1->x)
        y_end = v2->y;
    else
        y_end = v1->y;

    Bitval x_curr = Bitval_initf(v1->x, false, 9, 0);
    //int tid = x_curr.value/4;
    //TriangleBlock *t = top_triangle(&frameblocks[tid]);

    t->x_curr = x_curr;
    t->x2 = Bitval_initf(v2->x, false, 9, 0);
    t->x3 = Bitval_initf(v3->x, false, 9, 0);
    t->y_start = Bitval_initf(v1->y, false, 8, 9);
    t->y_end = Bitval_initf(y_end, false, 8, 9);
    t->y2 = Bitval_initf(v2->y, false, 8, 0);
    t->m1 = Bitval_initf(m1, true, 8, 9);
    t->m2 = Bitval_initf(m2, true, 8, 9);
    t->m3 = Bitval_initf(m3, true, 8, 9);
    t->z1 = Bitval_initf(v1->z, false, 15, 9);
    t->mz = Bitval_initf(mz, true, 15, 9);
    t->nz = Bitval_initf(nz, true, 15, 9);
    t->r1 = Bitval_initf(v1->r, false, 5, 9);
    t->mr = Bitval_initf(mr, true, 5, 9);
    t->nr = Bitval_initf(nr, true, 5, 9);
    t->g1 = Bitval_initf(v1->g, false, 6, 9);
    t->mg = Bitval_initf(mg, true, 6, 9);
    t->ng = Bitval_initf(ng, true, 6, 9);
    t->b1 = Bitval_initf(v1->b, false, 5, 9);
    t->mb = Bitval_initf(mb, true, 5, 9);
    t->nb = Bitval_initf(nb, true, 5, 9);
    //t->u1 = Bitval_initf(v1->u, false, 12, 9);
    //t->mu = Bitval_initf(mu, true, 12, 9);
    //t->nu = Bitval_initf(nu, true, 12, 9);
    //t->v1 = Bitval_initf(v1->v, false, 12, 9);
    //t->mv = Bitval_initf(mv, true, 12, 9);
    //t->nv = Bitval_initf(nv, true, 12, 9);
    t->u1 = Bitval_initf(0, false, 12, 9);
    t->mu = Bitval_initf(0, true, 12, 9);
    t->nu = Bitval_initf(0, true, 12, 9);
    t->v1 = Bitval_initf(0, false, 12, 9);
    t->mv = Bitval_initf(0, true, 12, 9);
    t->nv = Bitval_initf(0, true, 12, 9);
    
    //add_triangle_count(&frameblocks[tid]);

    return true;
}

bool precalc(Vert* va, Vert* vb, Vert* vc, TriList* frameblocks)
{
    Vert* v1;
    Vert* v2;
    Vert* v3;
    if(!vert_sort(va, vb, vc, &v1, &v2, &v3)) return false;

    Bitval x_curr = Bitval_initf(v1->x, false, 9, 0);
    int tid = x_curr.value/4;
    TriangleBlock *t = top_triangle(&frameblocks[tid]);

    if(!precalc_triangle(v1, v2, v3, t)) return false;

    add_triangle_count(&frameblocks[tid]);
    return true;
}
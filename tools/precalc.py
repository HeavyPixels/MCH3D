from __future__ import annotations

# Converts a triangle to the PreCalc'd specification

class Vertex:
    def __init__(self,
                 x: float, y: float, z: float,
                 r: float, g: float, b: float,
                 u: float, v: float) -> None:
        self.x = x
        self.y = y
        self.z = z
        self.r = r
        self.g = g
        self.b = b
        self.u = u
        self.v = v

class Bitval:    
    def __init__(self, val: int|float, signed: bool, iwidth: int, fwidth: int = 0) -> None:
        self.width: int = iwidth + fwidth
        if signed:
            self.width += 1
        val = val * (1 << fwidth)
        if signed:
            val = max(min(val, (1 << (self.width-1)) - 1), -(1 << (self.width-1)))
        else:
            val = max(min(val, (1 << self.width) - 1), 0)
        self.val: int = int(val)

    @property
    def val(self) -> int:
        return self._val
    @val.setter
    def val(self, val: int) -> None:
        mask = (1 << self.width) - 1
        self._val = val & mask

    def __add__(self, other: Bitval) -> Bitval:
        return Bitval((self.val << other.width) + other.val, False, self.width + other.width)


def pack(x_curr: float, x2: float, x3: float,
         y_start: float, y_end: float, y2: float,
         m1: float, m2: float, m3: float,
         z_curr: float, mz: float, nz: float,
         r_curr: float, mr: float, nr: float,
         g_curr: float, mg: float, ng: float,
         b_curr: float, mb: float, nb: float,
         u_curr: float, mu: float, nu: float,
         v_curr: float, mv: float, nv: float,
         end_frameblock: int = 0,
         end_frame: int = 0) -> tuple(Bitval, Bitval):
    print(f"x_curr {x_curr} -> {hex(Bitval(x_curr, False, 9, 0).val)}" )
    print(f"x2 {x2} -> {hex(Bitval(x2, False, 9, 0).val)}")
    print(f"x3 {x3} -> {hex(Bitval(x3, False, 9, 0).val)}")
    print(f"y_start {y_start} -> {hex(Bitval(y_start, False, 8, 9).val)}")
    print(f"y_end {y_end} -> {hex(Bitval(y_end, False, 8, 9).val)}")
    print(f"y2 {y2} -> {hex(Bitval(y2, False, 8, 0).val)}")
    print(f"m1 {m1} -> {hex(Bitval(m1, True, 8, 9).val)}")
    print(f"m2 {m2} -> {hex(Bitval(m2, True, 8, 9).val)}")
    print(f"m3 {m3} -> {hex(Bitval(m3, True, 8, 9).val)}")
    print(f"z_curr {z_curr} -> {hex(Bitval(z_curr, False, 15, 9).val)}")
    print(f"r_curr {r_curr} -> {hex(Bitval(r_curr, False, 5, 9).val)}")
    print(f"g_curr {g_curr} -> {hex(Bitval(g_curr, False, 6, 9).val)}")
    print(f"b_curr {b_curr} -> {hex(Bitval(b_curr, False, 5, 9).val)}")
    print(f"u_curr {u_curr} -> {hex(Bitval(u_curr, False, 12, 9).val)}")
    print(f"v_curr {v_curr} -> {hex(Bitval(v_curr, False, 12, 9).val)}")
    print(f"mz {mz} -> {hex(Bitval(mz, True, 15, 9).val)}")
    print(f"nz {nz} -> {hex(Bitval(nz, True, 15, 9).val)}")
    print(f"mr {mr} -> {hex(Bitval(mr, True, 5, 9).val)}")
    print(f"nr {nr} -> {hex(Bitval(nr, True, 5, 9).val)}")
    print(f"mg {mg} -> {hex(Bitval(mg, True, 6, 9).val)}")
    print(f"ng {ng} -> {hex(Bitval(ng, True, 6, 9).val)}")
    print(f"mb {mb} -> {hex(Bitval(mb, True, 5, 9).val)}")
    print(f"nb {nb} -> {hex(Bitval(nb, True, 5, 9).val)}")
    print(f"mu {mu} -> {hex(Bitval(mu, True, 12, 9).val)}")
    print(f"nu {nu} -> {hex(Bitval(nu, True, 12, 9).val)}")
    print(f"mv {mv} -> {hex(Bitval(mv, True, 12, 9).val)}")
    print(f"nv {nv} -> {hex(Bitval(nv, True, 12, 9).val)}")

    first_word = (Bitval(x_curr, False, 9, 0) + Bitval(x2, False, 9, 0) + Bitval(x3, False, 9, 0)
                + Bitval(y_start, False, 8, 9) + Bitval(y_end, False, 8, 9) + Bitval(y2, False, 8, 0)
                + Bitval(m1, True, 8, 9) + Bitval(m2, True, 8, 9) + Bitval(m3, True, 8, 9)
                + Bitval(z_curr, False, 15, 9) + Bitval(r_curr, False, 5, 9) + Bitval(g_curr, False, 6, 9)
                + Bitval(b_curr, False, 5, 9) + Bitval(u_curr, False, 12, 9) + Bitval(v_curr, False, 12, 9)
                + Bitval(end_frameblock, False, 1) + Bitval(end_frame, False, 1)
                + Bitval(0, False, 6) # Reserved
    )
    second_word = (Bitval(mz, True, 15, 9) + Bitval(nz, True, 15, 9)
                 + Bitval(mr, True, 5, 9) + Bitval(nr, True, 5, 9)
                 + Bitval(mg, True, 6, 9) + Bitval(ng, True, 6, 9)
                 + Bitval(mb, True, 5, 9) + Bitval(nb, True, 5, 9)
                 + Bitval(mu, True, 12, 9) + Bitval(nu, True, 12, 9)
                 + Bitval(mv, True, 12, 9) + Bitval(nv, True, 12, 9)
                 + Bitval(0, False, 10) # Reserved
    )
    return (first_word, second_word)

def precalc(va: Vertex, vb: Vertex, vc: Vertex) -> tuple(Bitval, Bitval):
    if   va.x < vb.x and va.x < vc.x and vb.x < vc.x:
        v1 = va
        v2 = vb
        v3 = vc
    elif va.x < vb.x and va.x < vc.x and vb.x >= vc.x:
        v1 = va
        v2 = vc
        v3 = vb
    elif va.x >= vb.x and va.x < vc.x and vb.x < vc.x:
        v1 = vb
        v2 = va
        v3 = vc
    elif va.x < vb.x and va.x >= vc.x and vb.x >= vc.x:
        v1 = vc
        v2 = va
        v3 = vb
    elif va.x >= vb.x and va.x >= vc.x and vb.x < vc.x:
        v1 = vb
        v2 = vc
        v3 = va
    elif va.x >= vb.x and va.x >= vc.x and vb.x >= vc.x:
        v1 = vc
        v2 = vb
        v3 = va
    else:
        print("Impossible, what?")

    Q = (v2.x-v1.x)/(v3.x-v1.x)
    mz = (v3.z-v1.z)/(v3.x-v1.x)
    mr = (v3.r-v1.r)/(v3.x-v1.x)
    mg = (v3.g-v1.g)/(v3.x-v1.x)
    mb = (v3.b-v1.b)/(v3.x-v1.x)
    mu = (v3.u-v1.u)/(v3.x-v1.x)
    mv = (v3.v-v1.v)/(v3.x-v1.x)
    m1 = (v3.y-v1.y)/(v3.x-v1.x)
    if v2.x == v1.x:
        m2 = 0
    else:
        m2 = (v2.y-v1.y)/(v2.x-v1.x)
    if v3.x == v2.x:
        m3 = 0
    else:
        m3 = (v3.y-v2.y)/(v3.x-v2.x)
    nz = (v2.z-v1.z-Q*(v3.z-v1.z)) / (v2.y-v1.y-Q*(v3.y-v1.y))
    nr = (v2.r-v1.r-Q*(v3.r-v1.r)) / (v2.y-v1.y-Q*(v3.y-v1.y))
    ng = (v2.g-v1.g-Q*(v3.g-v1.g)) / (v2.y-v1.y-Q*(v3.y-v1.y))
    nb = (v2.b-v1.b-Q*(v3.b-v1.b)) / (v2.y-v1.y-Q*(v3.y-v1.y))
    nu = (v2.u-v1.u-Q*(v3.u-v1.u)) / (v2.y-v1.y-Q*(v3.y-v1.y))
    nv = (v2.v-v1.v-Q*(v3.v-v1.v)) / (v2.y-v1.y-Q*(v3.y-v1.y))

    if v2.x == v1.x:
        yend = v2.y
    else:
        yend = v1.y
    return pack(v1.x, v2.x, v3.x,
                v1.y, yend, v2.y,
                m1, m2, m3,
                v1.z, mz, nz,
                v1.r, mr, nr,
                v1.g, mg, ng,
                v1.b, mb, nb,
                v1.u, mu, nu,
                v1.v, mv, nv)

def end_frameblock() -> tuple(Bitval, Bitval):
    return pack(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0)

def end_frame() -> tuple(Bitval, Bitval):
    return pack(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1)

va = Vertex(160, 0, 1000, 31, 0, 0, 0, 0)
vb = Vertex(319, 120, 500, 0, 63, 0, 0, 0)
vc = Vertex(0, 239, 0, 0, 0, 31, 0, 0)
p = precalc(va, vb, vc)
print(hex(p[0].val))
print(hex(p[1].val))

va = Vertex(0, 0, 5000, 15, 31, 15, 0, 0)
vb = Vertex(319, 0, 5000, 15, 31, 15, 0, 0)
vc = Vertex(0, 239, 5000, 15, 31, 15, 0, 0)
p = precalc(va, vb, vc)
print(hex(p[0].val))
print(hex(p[1].val))

va = Vertex(319, 0, 5000, 15, 31, 15, 0, 0)
vb = Vertex(319, 239, 5000, 15, 31, 15, 0, 0)
vc = Vertex(0, 239, 5000, 15, 31, 15, 0, 0)
p = precalc(va, vb, vc)
print(hex(p[0].val))
print(hex(p[1].val))
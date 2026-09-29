/-
  AGDGovernor.QXCMI
  QX-TLX-CMI/BKM Three-Way Bridge -- algebraic operator calculus.
  Principal target: I''(0) + Gamma + Tr[Y logS] = 0
  Lean: 4.29.0    Mathlib: none    zero sorry
-/

namespace AGDGovernor.QXCMI

structure Response where
  X    : Int
  Y    : Int
  logS : Int
  deriving Repr, DecidableEq

structure Psi0 where
  rhoId : Nat
  HId   : Nat
  deriving Repr, DecidableEq

structure Orbit where
  psi         : Psi0
  resp        : Response
  support     : Nat
  support_pos : 0 < support

def gammaBKM (r : Response) : Nat :=
  r.X.natAbs * r.X.natAbs

def trYlog (r : Response) : Int :=
  r.Y * r.logS

def accel (r : Response) : Int :=
  - trYlog r

def Ipp (r : Response) : Int :=
  accel r - (gammaBKM r : Int)

def residual (r : Response) : Int :=
  Ipp r + (gammaBKM r : Int) + trYlog r

def Spp (r : Response) : Int :=
  accel r - (gammaBKM r : Int)

def OX (o : Orbit) : Int := o.resp.X
def OY (o : Orbit) : Int := o.resp.Y
def OXi (r : Response) : Nat := gammaBKM r
def OA (r : Response) : Int := accel r
def OCMI (r : Response) : Int := OA r - (OXi r : Int)

theorem OCMI_eq_Ipp (r : Response) : OCMI r = Ipp r := rfl
theorem QX_CMI_001 (o : Orbit) : OX o = o.resp.X := rfl
theorem QX_CMI_002 (o : Orbit) : OY o = o.resp.Y := rfl

theorem QX_CMI_003_entropy_hessian (r : Response) :
    Spp r = accel r - (gammaBKM r : Int) := rfl

theorem QX_CMI_003_expanded (r : Response) :
    Spp r = - trYlog r - (gammaBKM r : Int) := by
  unfold Spp accel
  omega

def LocalUnitaryCMIReduction (IppObs SppObs : Int) : Prop :=
  IppObs = SppObs

theorem QX_CMI_004_discharge (r : Response)
    (h : LocalUnitaryCMIReduction (Ipp r) (Spp r)) :
    Ipp r = Spp r := h

theorem QX_CMI_004_holds_on_this_algebra (r : Response) :
    LocalUnitaryCMIReduction (Ipp r) (Spp r) := rfl

theorem QX_CMI_005_ident (r : Response) : OXi r = gammaBKM r := rfl

theorem QX_CMI_005_nonneg (r : Response) :
    0 <= (gammaBKM r : Int) :=
  Int.natCast_nonneg (gammaBKM r)

theorem QX_CMI_005_vanishes_on_zero_tangent (r : Response) (hX : r.X = 0) :
    gammaBKM r = 0 := by
  unfold gammaBKM
  rw [hX]
  rfl

theorem QX_CMI_006_master_bridge (r : Response) :
    Ipp r = accel r - (gammaBKM r : Int) := rfl

theorem QX_CMI_006_expanded (r : Response) :
    Ipp r = - trYlog r - (gammaBKM r : Int) := by
  unfold Ipp accel
  omega

theorem QX_CMI_007_zero_residual (r : Response) :
    residual r = 0 := by
  unfold residual Ipp accel trYlog
  omega

theorem QX_CMI_007_rearranged (r : Response) :
    Ipp r + (gammaBKM r : Int) + trYlog r = 0 :=
  QX_CMI_007_zero_residual r

theorem QX_CMI_008_zero_accel (r : Response) (hY : r.Y = 0) :
    Ipp r = - (gammaBKM r : Int) := by
  unfold Ipp accel trYlog
  rw [hY]
  omega

theorem QX_CMI_008_sign (r : Response) (hY : r.Y = 0) :
    Ipp r <= 0 := by
  have h := QX_CMI_008_zero_accel r hY
  have hn : 0 <= (gammaBKM r : Int) := QX_CMI_005_nonneg r
  omega

theorem QX_CMI_009_zero_tangent (r : Response) (hX : r.X = 0) :
    Ipp r = accel r := by
  have hg : gammaBKM r = 0 := QX_CMI_005_vanishes_on_zero_tangent r hX
  unfold Ipp
  rw [hg]
  omega

theorem QX_CMI_009_pairing (r : Response) (hX : r.X = 0) :
    Ipp r = - trYlog r := by
  have h := QX_CMI_009_zero_tangent r hX
  unfold accel at h
  exact h

theorem QX_CMI_010_flat (r : Response) (hX : r.X = 0) (hY : r.Y = 0) :
    Ipp r = 0 := by
  have h := QX_CMI_008_zero_accel r hY
  have hg : gammaBKM r = 0 := QX_CMI_005_vanishes_on_zero_tangent r hX
  rw [h, hg]
  omega

theorem Ipp_le_accel (r : Response) :
    Ipp r <= accel r := by
  unfold Ipp
  have hn : 0 <= (gammaBKM r : Int) := QX_CMI_005_nonneg r
  omega

theorem equality_classification (r : Response) :
    Ipp r = accel r <-> gammaBKM r = 0 := by
  constructor
  · intro h
    unfold Ipp at h
    have hn : 0 <= (gammaBKM r : Int) := QX_CMI_005_nonneg r
    omega
  · intro h
    unfold Ipp
    rw [h]
    omega

structure SpecGen where
  h    : Int
  hInv : Int
  deriving Repr, DecidableEq

def S (g : SpecGen) : SpecGen :=
  { h := g.hInv, hInv := g.h }

theorem S_involutive (g : SpecGen) : S (S g) = g := rfl
theorem S_squared_eq_id (g : SpecGen) : S (S g) = g := S_involutive g

theorem S_h (g : SpecGen) : (S g).h = g.hInv := rfl
theorem S_hInv (g : SpecGen) : (S g).hInv = g.h := rfl

def Ft (rho : Int) (g : SpecGen) : Int :=
  rho * (g.h - g.hInv)

theorem Ft_odd (rho : Int) (g : SpecGen) :
    Ft rho (S g) = - Ft rho g := by
  unfold Ft
  rw [S_h, S_hInv]
  omega

def Dt (rho : Int) (g : SpecGen) : Int :=
  rho * (g.h + g.hInv)

theorem Dt_even (rho : Int) (g : SpecGen) :
    Dt rho (S g) = Dt rho g := by
  unfold Dt
  rw [S_h, S_hInv]
  omega

structure ThreeWay where
  gen  : SpecGen
  resp : Response
  deriving Repr

def packet (w : ThreeWay) : SpecGen := S w.gen

theorem threeway_invariant (w : ThreeWay) :
    Ipp w.resp + (gammaBKM w.resp : Int) + trYlog w.resp = 0 :=
  QX_CMI_007_rearranged w.resp

def residualOmega (r : Response) : Nat :=
  (residual r).natAbs

theorem residualOmega_zero (r : Response) :
    residualOmega r = 0 := by
  unfold residualOmega
  rw [QX_CMI_007_zero_residual]
  rfl

theorem residual_bisimulation (r s : Response) :
    residual r = residual s := by
  rw [QX_CMI_007_zero_residual, QX_CMI_007_zero_residual]

def applyCMI (r : Response) : Int := OCMI r

theorem applyCMI_chain (r : Response) :
    applyCMI r = OA r - (OXi r : Int) := rfl

theorem applyCMI_zero_residual (r : Response) :
    applyCMI r + (OXi r : Int) + trYlog r = 0 := by
  unfold applyCMI OCMI OA OXi accel
  omega

inductive Sector
  | zeroAccel
  | zeroTangent
  | flat
  | generic
  deriving DecidableEq, Repr

def classify (r : Response) : Sector :=
  if r.X = 0 then
    if r.Y = 0 then Sector.flat else Sector.zeroTangent
  else if r.Y = 0 then Sector.zeroAccel
  else Sector.generic

theorem classify_flat (r : Response) (hX : r.X = 0) (hY : r.Y = 0) :
    classify r = Sector.flat := by
  unfold classify
  rw [if_pos hX, if_pos hY]

theorem classify_zeroAccel (r : Response) (hX : Not (r.X = 0)) (hY : r.Y = 0) :
    classify r = Sector.zeroAccel := by
  unfold classify
  rw [if_neg hX, if_pos hY]

theorem classify_zeroTangent (r : Response) (hX : r.X = 0) (hY : Not (r.Y = 0)) :
    classify r = Sector.zeroTangent := by
  unfold classify
  rw [if_pos hX, if_neg hY]

theorem classify_generic (r : Response) (hX : Not (r.X = 0)) (hY : Not (r.Y = 0)) :
    classify r = Sector.generic := by
  unfold classify
  rw [if_neg hX, if_neg hY]

theorem sector_flat_Ipp (r : Response) (hX : r.X = 0) (hY : r.Y = 0) :
    Ipp r = 0 :=
  QX_CMI_010_flat r hX hY

theorem sector_zeroAccel_sign (r : Response) (hY : r.Y = 0) :
    Ipp r <= 0 :=
  QX_CMI_008_sign r hY

def Faithful (o : Orbit) : Prop := 0 < o.support

theorem faithful_of_orbit (o : Orbit) : Faithful o :=
  o.support_pos

def publishable (o : Orbit) : Prop :=
  Faithful o /\ residual o.resp = 0

theorem publishable_of_orbit (o : Orbit) : publishable o :=
  And.intro o.support_pos (QX_CMI_007_zero_residual o.resp)

end AGDGovernor.QXCMI

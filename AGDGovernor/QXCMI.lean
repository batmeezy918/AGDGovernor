/-
  AGDGovernor.QXCMI

  QX-TLX-CMI/BKM Three-Way Bridge -- algebraic operator calculus.

  Principal formal target (zero residual):

      I''(0) + Gamma_BKM(sigma; X) + Tr[Y log sigma] = 0

  with the sector corollaries

      Y = 0  ->  I'' = -Gamma_BKM <= 0
      X = 0  ->  I'' = -Tr[Y log sigma]
      X = Y = 0  ->  I'' = 0

  SCOPE (read this before quoting the file as a physics theorem):

  This module proves the algebraic identity that the corpus itself
  nominated as the Lean target. Observables are Int/Nat. Gamma is the
  discrete nonnegative proxy |X|^2. Acceleration is -Y * logS.
  I'' is the CMI-curvature operator O_A - O_Xi.

  What is Lean-verified here:
    * zero-residual closure
    * entropy-hessian algebra S'' = A - Gamma
    * CMI reduction as an explicit hypothesis, then discharged on this algebra
    * BKM nonnegativity of the discrete proxy
    * three sector theorems
    * spectral-inversion involution and odd/even observables
    * operator composition O_CMI = O_A - O_Xi
    * residual as an AGD-style Omega invariant (always 0)

  What is NOT Lean-verified here (and must not be advertised as VERIFIED):
    * partial trace on H_A tensor H_B tensor H_C
    * Frechet derivative of log on density operators
    * von Neumann entropy of a complex matrix
    * unitary orbit exp(-i t H) as a one-parameter group on B(H)
    * I'' = Gamma_ABC - Gamma_AB
    * a universal bound I'' <= Gamma_AB

  Those analytic facts remain named hypotheses. Execution and numerical
  agreement are not substitutes. Claim class stays FORMAL_PARTIAL for
  the Hilbert-space reading and Lean-verified for the residual algebra.

  Author: James Michael Darnell (JMKK)
  Lean: 4.29.0    Mathlib: none    zero sorry
-/

namespace AGDGovernor.QXCMI

/-!
  ## Carriers
-/

/-- Reduced first/second responses and the log-pairing scalar. -/
structure Response where
  X    : Int
  Y    : Int
  logS : Int
  deriving Repr, DecidableEq

/-- Initial pair (rho tag, generator tag). Analytic content lives outside. -/
structure Psi0 where
  rhoId : Nat
  HId   : Nat
  deriving Repr, DecidableEq

/-- An evaluated orbit: responses plus a support witness. -/
structure Orbit where
  psi         : Psi0
  resp        : Response
  support     : Nat
  support_pos : 0 < support

/-!
  ## Channel operators
-/

/-- Discrete BKM curvature proxy: Tr[X Dlog X] ~> |X|^2. Nonnegative by construction. -/
def gammaBKM (r : Response) : Nat :=
  r.X.natAbs * r.X.natAbs

/-- Pairing Tr[Y log sigma] as an Int bilinear form. -/
def trYlog (r : Response) : Int :=
  r.Y * r.logS

/-- Reduced acceleration A_sigma(Y) = -Tr[Y log sigma]. -/
def accel (r : Response) : Int :=
  - trYlog r

/-- CMI curvature I''(0) := A - Gamma. This is O_CMI. -/
def Ipp (r : Response) : Int :=
  accel r - (gammaBKM r : Int)

/-- Zero-residual functional R(rho, H). -/
def residual (r : Response) : Int :=
  Ipp r + (gammaBKM r : Int) + trYlog r

/-- Entropy Hessian S''(sigma) in the same algebra. -/
def Spp (r : Response) : Int :=
  accel r - (gammaBKM r : Int)

/-!
  ## Named operators (composition form)
-/

def OX (o : Orbit) : Int := o.resp.X
def OY (o : Orbit) : Int := o.resp.Y
def OXi (r : Response) : Nat := gammaBKM r
def OA (r : Response) : Int := accel r
def OCMI (r : Response) : Int := OA r - (OXi r : Int)

theorem OCMI_eq_Ipp (r : Response) : OCMI r = Ipp r := rfl

/-!
  ## QX-CMI-001 / 002 -- reduced derivatives as operator output
-/

theorem QX_CMI_001 (o : Orbit) : OX o = o.resp.X := rfl

theorem QX_CMI_002 (o : Orbit) : OY o = o.resp.Y := rfl

/-!
  ## QX-CMI-003 -- entropy Hessian identity
-/

theorem QX_CMI_003_entropy_hessian (r : Response) :
    Spp r = accel r - (gammaBKM r : Int) := rfl

theorem QX_CMI_003_expanded (r : Response) :
    Spp r = - trYlog r - (gammaBKM r : Int) := by
  unfold Spp accel
  omega

/-!
  ## QX-CMI-004 -- local-unitary CMI reduction, as a hypothesis class

  The Hilbert-space statement I(A:C|B)'' = S(rho_BC)'' is not proved
  here. It is the gate that turns the entropy Hessian into a CMI theorem.
-/

def LocalUnitaryCMIReduction (IppObs SppObs : Int) : Prop :=
  IppObs = SppObs

theorem QX_CMI_004_discharge (r : Response)
    (h : LocalUnitaryCMIReduction (Ipp r) (Spp r)) :
    Ipp r = Spp r := h

theorem QX_CMI_004_holds_on_this_algebra (r : Response) :
    LocalUnitaryCMIReduction (Ipp r) (Spp r) := rfl

/-!
  ## QX-CMI-005 -- BKM identification and positivity of the proxy
-/

theorem QX_CMI_005_ident (r : Response) :
    OXi r = gammaBKM r := rfl

theorem QX_CMI_005_nonneg (r : Response) :
    0 ≤ (gammaBKM r : Int) :=
  Int.ofNat_zero_le (gammaBKM r)

theorem QX_CMI_005_vanishes_on_zero_tangent (r : Response) (hX : r.X = 0) :
    gammaBKM r = 0 := by
  unfold gammaBKM
  rw [hX]
  rfl

/-!
  ## QX-CMI-006 -- master bridge  I'' = A - Gamma
-/

theorem QX_CMI_006_master_bridge (r : Response) :
    Ipp r = accel r - (gammaBKM r : Int) := rfl

theorem QX_CMI_006_expanded (r : Response) :
    Ipp r = - trYlog r - (gammaBKM r : Int) := by
  unfold Ipp accel
  omega

/-!
  ## QX-CMI-007 -- zero-residual closure  (principal target)
-/

theorem QX_CMI_007_zero_residual (r : Response) :
    residual r = 0 := by
  unfold residual Ipp accel trYlog
  omega

theorem QX_CMI_007_rearranged (r : Response) :
    Ipp r + (gammaBKM r : Int) + trYlog r = 0 :=
  QX_CMI_007_zero_residual r

/-!
  ## QX-CMI-008 -- zero-acceleration sector
-/

theorem QX_CMI_008_zero_accel (r : Response) (hY : r.Y = 0) :
    Ipp r = - (gammaBKM r : Int) := by
  unfold Ipp accel trYlog
  rw [hY]
  omega

theorem QX_CMI_008_sign (r : Response) (hY : r.Y = 0) :
    Ipp r ≤ 0 := by
  have h := QX_CMI_008_zero_accel r hY
  have hn : 0 ≤ (gammaBKM r : Int) := QX_CMI_005_nonneg r
  omega

/-!
  ## QX-CMI-009 -- zero-tangent sector
-/

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

/-!
  ## QX-CMI-010 -- flat orbit
-/

theorem QX_CMI_010_flat (r : Response) (hX : r.X = 0) (hY : r.Y = 0) :
    Ipp r = 0 := by
  have h := QX_CMI_008_zero_accel r hY
  have hg : gammaBKM r = 0 := QX_CMI_005_vanishes_on_zero_tangent r hX
  rw [h, hg]
  omega

/-!
  ## Conditional comparison  I'' <= A   (Gamma >= 0)
-/

theorem Ipp_le_accel (r : Response) :
    Ipp r ≤ accel r := by
  unfold Ipp
  have hn : 0 ≤ (gammaBKM r : Int) := QX_CMI_005_nonneg r
  omega

theorem equality_classification (r : Response) :
    Ipp r = accel r <-> gammaBKM r = 0 := by
  constructor
  · intro h
    unfold Ipp at h
    have hn : 0 ≤ (gammaBKM r : Int) := QX_CMI_005_nonneg r
    omega
  · intro h
    unfold Ipp
    rw [h]
    omega

/-!
  ## Spectral-inversion channel (parallel, not inserted into CMI)
-/

structure SpecGen where
  h    : Int
  hInv : Int
  deriving Repr, DecidableEq

def S : SpecGen -> SpecGen
  | ⟨h, hInv⟩ => ⟨hInv, h⟩

theorem S_involutive (g : SpecGen) : S (S g) = g := by
  cases g
  rfl

theorem S_squared_eq_id (g : SpecGen) : S (S g) = g :=
  S_involutive g

/-- Odd observable: F(S g) = -F(g). -/
def Ft (rho : Int) (g : SpecGen) : Int :=
  rho * (g.h - g.hInv)

theorem Ft_odd (rho : Int) (g : SpecGen) :
    Ft rho (S g) = - Ft rho g := by
  cases g
  unfold Ft S
  omega

/-- Even observable: D(S g) = D(g). -/
def Dt (rho : Int) (g : SpecGen) : Int :=
  rho * (g.h + g.hInv)

theorem Dt_even (rho : Int) (g : SpecGen) :
    Dt rho (S g) = Dt rho g := by
  cases g
  unfold Dt S
  omega

/-!
  ## Three-way packet
-/

structure ThreeWay where
  gen  : SpecGen
  resp : Response
  deriving Repr

/-- Q(rho, H) = (H^{-1}, X, Y, Gamma, A, I''). -/
def packet (w : ThreeWay) : SpecGen × Int × Int × Nat × Int × Int :=
  (S w.gen, w.resp.X, w.resp.Y, gammaBKM w.resp, accel w.resp, Ipp w.resp)

theorem threeway_invariant (w : ThreeWay) :
    Ipp w.resp + (gammaBKM w.resp : Int) + trYlog w.resp = 0 :=
  QX_CMI_007_rearranged w.resp

/-!
  ## Residual as an AGD Omega invariant
-/

def residualOmega (r : Response) : Nat :=
  (residual r).natAbs

theorem residualOmega_zero (r : Response) :
    residualOmega r = 0 := by
  unfold residualOmega
  rw [QX_CMI_007_zero_residual]
  rfl

/-- Every orbit evaluates to the same residual observable. -/
theorem residual_bisimulation (r s : Response) :
    residual r = residual s := by
  rw [QX_CMI_007_zero_residual, QX_CMI_007_zero_residual]

/-!
  ## Operator diagram as a composable function
-/

def applyCMI (r : Response) : Int := OCMI r

theorem applyCMI_chain (r : Response) :
    applyCMI r = OA r - (OXi r : Int) := rfl

theorem applyCMI_zero_residual (r : Response) :
    applyCMI r + (OXi r : Int) + trYlog r = 0 := by
  unfold applyCMI OCMI OA OXi accel
  omega

/-!
  ## Sector table
-/

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

theorem classify_zeroAccel (r : Response) (hX : r.X ≠ 0) (hY : r.Y = 0) :
    classify r = Sector.zeroAccel := by
  unfold classify
  rw [if_neg hX, if_pos hY]

theorem classify_zeroTangent (r : Response) (hX : r.X = 0) (hY : r.Y ≠ 0) :
    classify r = Sector.zeroTangent := by
  unfold classify
  rw [if_pos hX, if_neg hY]

theorem classify_generic (r : Response) (hX : r.X ≠ 0) (hY : r.Y ≠ 0) :
    classify r = Sector.generic := by
  unfold classify
  rw [if_neg hX, if_neg hY]

theorem sector_flat_Ipp (r : Response) (hX : r.X = 0) (hY : r.Y = 0) :
    Ipp r = 0 :=
  QX_CMI_010_flat r hX hY

theorem sector_zeroAccel_sign (r : Response) (hY : r.Y = 0) :
    Ipp r ≤ 0 :=
  QX_CMI_008_sign r hY

/-!
  ## Support gate -- faithful-state hypothesis as a predicate
-/

def Faithful (o : Orbit) : Prop := 0 < o.support

theorem faithful_of_orbit (o : Orbit) : Faithful o :=
  o.support_pos

/-- Publishable only when support is positive and residual is zero. -/
def publishable (o : Orbit) : Prop :=
  Faithful o ∧ residual o.resp = 0

theorem publishable_of_orbit (o : Orbit) : publishable o :=
  And.intro o.support_pos (QX_CMI_007_zero_residual o.resp)

end AGDGovernor.QXCMI

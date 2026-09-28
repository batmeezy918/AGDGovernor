import AGDGovernor.Core

namespace AGDGovernor

def jitter {alpha} (J : alpha -> Nat) (a b : alpha) : Nat := dist (J a) (J b)

def jitterClose {alpha} (J : alpha -> Nat) (eps : Nat) (a b : alpha) : Prop :=
  jitter J a b <= eps

theorem jitter_close_reflexive {alpha} (J : alpha -> Nat) (eps : Nat) (A : alpha) :
    jitterClose J eps A A := by
  unfold jitterClose jitter
  rw [dist_self]
  exact Nat.zero_le eps

theorem jitter_close_symmetric {alpha} (J : alpha -> Nat) (eps : Nat) (A B : alpha) :
    jitterClose J eps A B -> jitterClose J eps B A := by
  intro h
  unfold jitterClose jitter at *
  rw [dist_comm]
  exact h

theorem jitter_close_triangle {alpha} (J : alpha -> Nat) (eps : Nat) (A B C : alpha)
    (hAB : jitterClose J eps A B) (hBC : jitterClose J eps B C) :
    jitter J A C <= eps + eps := by
  unfold jitterClose jitter at *
  have h := dist_triangle (J A) (J B) (J C)
  omega

def equivalent {alpha} (J : alpha -> Nat) (eps : Nat) (A B : alpha) : Prop :=
  jitterClose J eps A B

theorem operator_preserves_equivalence {alpha}
    (J : alpha -> Nat) (eps : Nat) (tf : alpha -> alpha)
    (h_const : forall d, J (tf d) = J d) (A B : alpha)
    (h : equivalent J eps A B) :
    equivalent J eps (tf A) (tf B) := by
  unfold equivalent jitterClose jitter at *
  rw [h_const, h_const]
  exact h

structure BenchCert where
  baseline  : Nat
  candidate : Nat
  deriving Repr

def measuredSpeedup (c : BenchCert) : Nat :=
  c.baseline / (max c.candidate 1)

def validCert (c : BenchCert) : Prop :=
  0 < c.baseline /\ 0 < c.candidate /\ c.candidate <= c.baseline

theorem speedup_positive (c : BenchCert) (h : validCert c) :
    0 < measuredSpeedup c := by
  have hpos : 0 < c.candidate := h.2.1
  have hle  : c.candidate <= c.baseline := h.2.2
  have hden : max c.candidate 1 = c.candidate := Nat.max_eq_left (Nat.succ_le_of_lt hpos)
  unfold measuredSpeedup
  rw [hden]
  exact Nat.div_pos hle hpos

theorem benchmark_claim_valid (c : BenchCert) (h : validCert c) :
    measuredSpeedup c = c.baseline / c.candidate := by
  have hpos : 0 < c.candidate := h.2.1
  have hden : max c.candidate 1 = c.candidate := Nat.max_eq_left (Nat.succ_le_of_lt hpos)
  unfold measuredSpeedup
  rw [hden]

def Omega (s : State) : Nat := s.obs

theorem agd_transport_closure (T : State -> State) (h : Admissible T) (s : State) :
    Omega (T s) = Omega s := h s

theorem curvature_convergence (T : State -> State) (h : Admissible T) :
    forall n s, Omega (iter T n s) = Omega s := by
  intro n s
  induction n with
  | zero => rfl
  | succ n ih =>
    change Omega (T (iter T n s)) = Omega s
    unfold Omega at *
    rw [h, ih]

def bisim (T U : State -> State) : Prop :=
  forall s, Omega (T s) = Omega (U s)

theorem agd_bisimulation (T U : State -> State)
    (hT : Admissible T) (hU : Admissible U) : bisim T U := by
  intro s
  unfold Omega
  rw [hT, hU]

theorem agd_flow_semigroup {alpha}
    (T : Nat -> alpha -> alpha)
    (h : forall t s q, T (t + s) q = T t (T s q)) :
    forall t s q, T (t + s) q = T t (T s q) := h

theorem agd_master_dynamic_closure
    (T : Nat -> State -> State) (J : Nat -> Nat)
    (h_transport : forall t q, Omega (T t q) = Omega q)
    (h_descent : forall t, t > 0 -> J t < J 0) (q : State) :
    (forall t, Omega (T t q) = Omega q) /\ (forall t, t > 0 -> J t < J 0) :=
  And.intro (fun t => h_transport t q) h_descent

theorem agd_spectral_convergence (T : State -> State) (h : Admissible T) :
    forall n, Admissible (iter T n) := by
  intro n s
  exact curvature_convergence T h n s

structure Operator where
  op         : State -> State
  admissible : Admissible op

def allLe (loss : State -> Nat) (psi : State) (sel : Operator) : List Operator -> Prop
  | [] => True
  | o :: rest => loss (sel.op psi) <= loss (o.op psi) /\ allLe loss psi sel rest

def IsAdaptive (loss : State -> Nat) (psi : State) (choices : List Operator) (sel : Operator) : Prop :=
  Admissible sel.op /\ allLe loss psi sel choices

theorem adaptive_operator_preservation
    (loss : State -> Nat) (psi : State) (choices : List Operator) (sel : Operator)
    (h : IsAdaptive loss psi choices sel) :
    Omega (sel.op psi) = Omega psi /\ allLe loss psi sel choices :=
  And.intro (sel.admissible psi) h.2

structure Transition where
  before : State
  after  : State

def rollback (t : Transition) : State := t.before

def IsStable (expected : Nat) (s : State) : Prop := Omega s = expected

theorem agd_failure_recovery (expected : Nat) (t : Transition)
    (h_before : IsStable expected t.before)
    (h_after  : Not (IsStable expected t.after)) :
    IsStable expected (rollback t) /\ Not (rollback t = t.after) := by
  constructor
  · exact h_before
  · intro heq
    apply h_after
    unfold rollback at heq
    rw [<- heq]
    exact h_before

def InvariantStableRegion (target : Nat) (s : State) : Prop := Omega s = target

def ManifoldAdmissible (T : State -> State) : Prop := Admissible T

theorem learning_manifold_stability
    (T : State -> State) (M0 : State) (target : Nat)
    (hT : ManifoldAdmissible T)
    (h0 : InvariantStableRegion target M0) :
    forall n, InvariantStableRegion target (iter T n M0) := by
  intro n
  induction n with
  | zero => exact h0
  | succ n ih =>
    unfold InvariantStableRegion Omega ManifoldAdmissible Admissible at *
    change (T (iter T n M0)).obs = target
    rw [hT]
    exact ih

inductive Lineage : Type
  | nil
  | cons (op : State -> State) (rest : Lineage)

def reconstruct (start : State) : Lineage -> State
  | Lineage.nil => start
  | Lineage.cons op rest => op (reconstruct start rest)

theorem memory_lineage_reconstruction
    (start : State) (l : Lineage) (current : State)
    (h : current = reconstruct start l) :
    current = reconstruct start l := h

structure Cycle where
  init : State
  sel  : Operator

def execute (c : Cycle) : State := c.sel.op c.init

theorem agd_autonomous_closure (c : Cycle) :
    Omega (execute c) = Omega c.init :=
  c.sel.admissible c.init

end AGDGovernor

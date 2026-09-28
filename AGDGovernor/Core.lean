/-
  AGDGovernor.Core

  Mathlib-free carriers for the July 2026 AGD theorem zip.
  Observables are Nat. This is the governor kernel, not a Real analysis port.
  Zero sorry.
-/

namespace AGDGovernor

/-- Discrete AGD state. `obs` is the declared observable. -/
structure State where
  id  : Nat
  obs : Nat
  deriving Repr, DecidableEq

/-- Absolute difference on Nat. -/
def dist (a b : Nat) : Nat :=
  if a ≥ b then a - b else b - a

theorem dist_comm (a b : Nat) : dist a b = dist b a := by
  unfold dist
  split <;> split <;> omega

theorem dist_self (a : Nat) : dist a a = 0 := by
  unfold dist
  simp

theorem dist_triangle (a b c : Nat) : dist a c ≤ dist a b + dist b c := by
  unfold dist
  split <;> split <;> split <;> omega

/-- Iterate an endomap. -/
def iter {α} (f : α → α) : Nat → α → α
  | 0, x => x
  | n + 1, x => f (iter f n x)

theorem iter_zero {α} (f : α → α) (x : α) : iter f 0 x = x := rfl

theorem iter_succ {α} (f : α → α) (n : Nat) (x : α) :
    iter f (n + 1) x = f (iter f n x) := rfl

/-- An operator is admissible when it preserves the observable. -/
def Admissible (T : State → State) : Prop :=
  ∀ s, (T s).obs = s.obs

def intertwines (π : State → Nat) (T : State → State) (Tbar : Nat → Nat) : Prop :=
  ∀ s, π (T s) = Tbar (π s)

theorem intertwining_iterate
    (π : State → Nat) (T : State → State) (Tbar : Nat → Nat)
    (h : intertwines π T Tbar) :
    ∀ n s, π (iter T n s) = iter Tbar n (π s) := by
  intro n s
  induction n with
  | zero => simp [iter]
  | succ n ih =>
    simp [iter, intertwines] at *
    rw [h, ih]

end AGDGovernor

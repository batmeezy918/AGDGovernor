/-
  AGDGovernor.Core

  Mathlib-free carriers for the July 2026 AGD theorem zip.
  Observables are Nat. This is the governor kernel, not a Real analysis port.
  Zero sorry. ASCII binders only.
-/

namespace AGDGovernor

structure State where
  id  : Nat
  obs : Nat
  deriving Repr, DecidableEq

def dist (a b : Nat) : Nat :=
  if a >= b then a - b else b - a

theorem dist_comm (a b : Nat) : dist a b = dist b a := by
  unfold dist
  split <;> split <;> omega

theorem dist_self (a : Nat) : dist a a = 0 := by
  unfold dist
  simp

theorem dist_triangle (a b c : Nat) : dist a c <= dist a b + dist b c := by
  unfold dist
  split <;> split <;> split <;> omega

def iter {alpha} (f : alpha -> alpha) : Nat -> alpha -> alpha
  | 0, x => x
  | n + 1, x => f (iter f n x)

theorem iter_zero {alpha} (f : alpha -> alpha) (x : alpha) : iter f 0 x = x := rfl

theorem iter_succ {alpha} (f : alpha -> alpha) (n : Nat) (x : alpha) :
    iter f (n + 1) x = f (iter f n x) := rfl

def Admissible (T : State -> State) : Prop :=
  forall s, (T s).obs = s.obs

def intertwines (pi : State -> Nat) (T : State -> State) (Tbar : Nat -> Nat) : Prop :=
  forall s, pi (T s) = Tbar (pi s)

theorem intertwining_iterate
    (pi : State -> Nat) (T : State -> State) (Tbar : Nat -> Nat)
    (h : intertwines pi T Tbar) :
    forall n s, pi (iter T n s) = iter Tbar n (pi s) := by
  intro n s
  induction n with
  | zero => simp [iter]
  | succ n ih =>
    simp [iter, intertwines] at *
    rw [h, ih]

end AGDGovernor

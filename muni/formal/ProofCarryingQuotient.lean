import Mathlib

namespace AGD

structure Program where
  State : Type
  step : State → State

structure Transformation (P : Program) where
  CandidateState : Type
  candidate_step : CandidateState → CandidateState
  project : P.State → CandidateState
  reconstruct : CandidateState → P.State
  forward_closed : ∀ x, project (P.step x) = candidate_step (project x)
  observable : P.State → Prop
  reconstruct_closed : ∀ x, observable x → reconstruct (project x) = x

def SemPres {P : Program} (T : Transformation P) : Prop :=
  ∀ x, T.project (P.step x) = T.candidate_step (T.project x)

def GapClosed {P : Program} (T : Transformation P) : Prop :=
  T.forward_closed

def Admissible {P : Program} (T : Transformation P) : Prop :=
  SemPres T ∧ GapClosed T

theorem certified_step {P : Program} (T : Transformation P) :
    GapClosed T → SemPres T := by
  intro h x
  exact h x

theorem CertifiedCompile {P : Program} (T : Transformation P) :
    Admissible T → SemPres T := by
  intro h
  exact h.1

theorem certified_reconstruction {P : Program} (T : Transformation P) :
    ∀ x, T.observable x → T.reconstruct (T.project x) = x := by
  intro x hx
  exact T.reconstruct_closed x hx

end AGD

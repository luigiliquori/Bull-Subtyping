
Module Types.
  Inductive IntersectionType : Set :=
  | Var : nat -> IntersectionType
  | Arr : IntersectionType -> IntersectionType -> IntersectionType
  | Inter : IntersectionType -> IntersectionType -> IntersectionType
  | Omega : IntersectionType.

  Notation "σ → τ" := (Arr σ τ) (at level 88, right associativity).
  Notation "σ ∩ τ" := (Inter σ τ) (at level 80, right associativity).
  Definition ω := (Omega).

  Module SubtypeRelation.
    Reserved Notation "σ ≤ τ" (at level 89).
    Reserved Notation "σ ~ τ" (at level 89).
    
    Require Import Coq.Relations.Relation_Operators.
    Local Reserved Notation "σ ≤[ R ] τ" (at level 89).

    Inductive SubtypeRules {R : IntersectionType -> IntersectionType -> Prop}: IntersectionType -> IntersectionType -> Prop :=
    | R_InterMeetLeft : forall σ τ, σ ∩ τ ≤[R] σ
    | R_InterMeetRight : forall σ τ, σ ∩ τ ≤[R] τ
    | R_InterIdem : forall τ, τ ≤[R] τ ∩ τ
    | R_InterDistrib : forall σ τ ρ,
        (σ → ρ) ∩ (σ → τ) ≤[R] σ → ρ ∩ τ
    | R_SubtyDistrib: forall (σ σ' τ τ' : IntersectionType),
        R σ σ' -> R τ τ' -> σ ∩ τ ≤[R] σ' ∩ τ'
    | R_CoContra : forall σ σ' τ τ',
        R σ σ' -> R τ τ' -> σ' → τ ≤[R] σ → τ'
    | R_OmegaTop : forall σ, σ ≤[R] ω
    | R_OmegaArrow : ω ≤[R] ω → ω
    where "σ ≤[ R ] τ" := (SubtypeRules (R := R) σ τ).

    Definition SubtypeRules_Closure {R : IntersectionType -> IntersectionType -> Prop}: IntersectionType -> IntersectionType -> Prop :=
      clos_refl_trans IntersectionType (@SubtypeRules R).
    Local Notation "σ ≤*[ R ] τ" := (@SubtypeRules_Closure R σ τ) (at level 89).
    Local Reserved Notation "σ ≤* τ" (at level 89).

    Unset Elimination Schemes.
    Inductive Subtypes: IntersectionType -> IntersectionType -> Prop :=
    | ST : forall σ τ, σ ≤* τ -> σ ≤ τ
    where "σ ≤ τ" := (Subtypes σ τ)
      and "σ ≤* τ" := (σ ≤*[Subtypes] τ).
    Set Elimination Schemes.

    Hint Unfold SubtypeRules_Closure.
    Definition unST: forall σ τ, σ ≤ τ -> σ ≤* τ :=
      fun _ _ p =>
        match p with
        | ST _ _ p' => p'
        end.
    
    Coercion unST: Subtypes >-> SubtypeRules_Closure.
    
    Section Subtypes_ind.
      Variable P : IntersectionType -> IntersectionType -> Prop.
      Hypothesis InterMeetLeft_case: 
        forall σ τ : IntersectionType, P (σ ∩ τ) σ.
      Hypothesis InterMeetRight_case:
        forall σ τ : IntersectionType, P (σ ∩ τ) τ.
      Hypothesis InterIdem_case:
        forall τ : IntersectionType, P τ (τ ∩ τ).
      Hypothesis InterDistrib_case:
        forall σ τ ρ : IntersectionType, P ((σ → ρ) ∩ (σ → τ)) (σ → ρ ∩ τ).
      Hypothesis SubtyDistrib_case:
        forall σ σ': IntersectionType, σ ≤ σ' -> P σ σ' ->
          forall τ τ': IntersectionType, τ ≤ τ' -> P τ τ' ->
          P (σ ∩ τ) (σ' ∩ τ').
      Hypothesis CoContra_case:
        forall σ σ': IntersectionType, σ ≤ σ' -> P σ σ' ->
        forall τ τ': IntersectionType, τ ≤ τ' -> P τ τ' ->
        P (σ' → τ) (σ → τ').
      Hypothesis OmegaTop_case:
        forall σ : IntersectionType, P σ ω.
      Hypothesis OmegaArrow_case:
        P ω (ω → ω).
      Hypothesis Refl_case:
        forall σ : IntersectionType, P σ σ.

      Hypothesis Trans_case:
        forall σ τ : IntersectionType, σ ≤ τ -> P σ τ ->
        forall ρ : IntersectionType, τ ≤ ρ -> P τ ρ ->
        P σ ρ.

      Fixpoint Subtypes_ind {σ τ : IntersectionType} (p : σ ≤ τ) {struct p}: P σ τ :=
        match p in σ ≤ τ return P σ τ with
        | ST σ τ p' =>
          ((fix subtypes_closure_ind (σ τ : IntersectionType) (p : σ ≤* τ) {struct p}: P σ τ := 
            match p in (clos_refl_trans _ _ _ τ)return P σ τ with
            | rt_step τ p' =>
                ((fix subtypes_rules_ind (σ τ : IntersectionType) (p : σ ≤[Subtypes] τ) {struct p}: P σ τ :=
                  match p in σ ≤[_] τ return P σ τ with
                  | R_InterMeetLeft σ τ => InterMeetLeft_case σ τ
                  | R_InterMeetRight σ τ  => InterMeetRight_case σ τ
                  | R_InterIdem σ => InterIdem_case σ
                  | R_SubtyDistrib σ σ' τ τ' lteSigmaSigma' lteTauTau' =>
                         SubtyDistrib_case σ σ' lteSigmaSigma' (Subtypes_ind lteSigmaSigma')
                                           τ τ' lteTauTau' (Subtypes_ind lteTauTau')
                  | R_InterDistrib σ τ ρ =>
                      InterDistrib_case σ τ ρ
                  | R_CoContra σ σ' τ τ' lteSigmaSigma' lteTauTau' =>
                      CoContra_case σ σ' lteSigmaSigma' (Subtypes_ind lteSigmaSigma')
                                    τ τ' lteTauTau' (Subtypes_ind lteTauTau')
                  | R_OmegaTop σ =>
                      OmegaTop_case σ
                  | R_Omega_Arrow =>
                      OmegaArrow_case
                  end) σ τ p')
            | rt_refl => Refl_case σ
            | rt_trans τ ρ p1 p2 => 
                Trans_case σ τ (ST σ τ p1) (subtypes_closure_ind σ τ p1)
                           ρ (ST τ ρ p2) (subtypes_closure_ind τ ρ p2)
            end) σ τ p')
        end.
    End Subtypes_ind.
    
    Section Subtypes_ind_left.
      Variable σ : IntersectionType.
      Variable P : IntersectionType -> Prop.
      Hypothesis Start : P σ.
      Hypothesis Step : forall τ ρ, σ ≤ τ -> P τ -> τ ≤[Subtypes] ρ -> P ρ.

      Require Import Relations.Operators_Properties.
      
      Definition Subtypes_ind_left: forall τ, σ ≤ τ -> P τ :=
        let LiftStep : forall τ ρ, σ ≤* τ -> P τ -> τ ≤[Subtypes] ρ -> P ρ :=
          fun τ ρ => fun p1 r p2 => Step τ ρ (ST _ _ p1) r p2 in
        fun τ p =>
          clos_refl_trans_ind_left _ _ σ P Start LiftStep τ (unST _ _ p).
    End Subtypes_ind_left.
    
    Section Subtypes_ind_right.
      Variable ρ : IntersectionType.
      Variable P : IntersectionType -> Prop.
      Hypothesis Start : P ρ.
      Hypothesis Step : forall σ τ, σ ≤[Subtypes] τ -> P τ -> τ ≤ ρ -> P σ.

      Require Import Relations.Operators_Properties.
      Definition Subtypes_ind_right: forall σ, σ ≤ ρ -> P σ :=
        let LiftStep : forall σ τ, σ ≤[Subtypes] τ -> P τ -> τ ≤* ρ -> P σ :=
          fun σ τ => fun p1 r p2 => Step σ τ p1 r (ST _ _ p2) in
        fun σ p =>
          clos_refl_trans_ind_right _ _ P ρ Start LiftStep σ (unST _ _ p).
    End Subtypes_ind_right.
    

    Definition liftSubtypeProof {σ τ} (p : σ ≤[Subtypes] τ): σ ≤ τ :=
      ST _ _ (rt_step _ _ _ _ p).

    Definition InterMeetLeft {σ τ}: σ ∩ τ ≤ σ := 
      liftSubtypeProof (R_InterMeetLeft σ τ).
    Definition InterMeetRight {σ τ}: σ ∩ τ ≤ τ :=
      liftSubtypeProof (R_InterMeetRight σ τ).
    Definition InterIdem {τ}: τ ≤ τ ∩ τ :=
      liftSubtypeProof (R_InterIdem τ).
    Definition InterDistrib {σ τ ρ}: (σ → ρ) ∩ (σ → τ) ≤ σ → ρ ∩ τ :=
      liftSubtypeProof (R_InterDistrib σ τ ρ).
    Definition SubtyDistrib {σ σ' τ τ'}: σ ≤ σ' -> τ ≤ τ' -> σ ∩ τ ≤ σ' ∩ τ' :=
      fun p1 p2 => liftSubtypeProof (R_SubtyDistrib σ σ' τ τ' p1 p2).
    Definition CoContra {σ σ' τ τ'}: σ ≤ σ' -> τ ≤ τ' -> σ' → τ ≤ σ → τ' :=
      fun p1 p2 => liftSubtypeProof (R_CoContra σ σ' τ τ' p1 p2).
    Definition OmegaTop {σ}: σ ≤ ω :=
      liftSubtypeProof (R_OmegaTop σ).
    Definition OmegaArrow: ω ≤ ω → ω :=
      liftSubtypeProof (R_OmegaArrow).
    

    Inductive EqualTypes : IntersectionType -> IntersectionType -> Prop :=
    | InducedEq {σ τ}: σ ≤ τ -> τ ≤ σ -> σ ~ τ
    where "σ ~ τ" := (EqualTypes σ τ).
      
    Definition EqualTypesAreSubtypes_left: forall σ τ, σ ~ τ -> σ ≤ τ :=
      fun _ _ eqtys =>
        match eqtys with
        | InducedEq _ _ l _ => l
        end.
    Definition EqualTypesAreSubtypes_right: forall σ τ, σ ~ τ -> τ ≤ σ :=
      fun _ _ eqtys => 
        match eqtys with
        | InducedEq _ _ _ r => r
        end.
    Coercion EqualTypesAreSubtypes_left : EqualTypes >-> Subtypes.
    Coercion EqualTypesAreSubtypes_right : EqualTypes >-> Subtypes.
     
    Hint Resolve InterMeetLeft InterMeetRight InterIdem InterDistrib OmegaTop OmegaArrow InducedEq.

    Require Import Coq.Classes.RelationClasses.
    Require Import Coq.Relations.Operators_Properties.
    Require Import Coq.Relations.Relation_Definitions.
    Instance Subtypes_Reflexive : Reflexive Subtypes :=
      fun σ => ST _ _ ((clos_rt_is_preorder _ _).(preord_refl _ _) σ).
    Instance Subtypes_Transitive : Transitive Subtypes := 
      fun σ τ ρ p1 p2 => ST _ _ ((clos_rt_is_preorder _ _).(preord_trans _ _) σ τ ρ (unST _ _ p1) (unST _ _ p2)).
    Instance Subtypes_Preorder : PreOrder Subtypes :=
      {| PreOrder_Reflexive := Subtypes_Reflexive; 
         PreOrder_Transitive := Subtypes_Transitive |}.

    Instance EqualTypes_Reflexive: Reflexive EqualTypes :=
      fun σ => InducedEq (reflexivity σ) (reflexivity σ).
    Instance EqualTypes_Transitive: Transitive EqualTypes.
    Proof.
      unfold Transitive.
      intros.
      destruct H.
      destruct H0.
      eapply InducedEq.
      exact (transitivity H H0).
      exact (transitivity H2 H1).
    Qed.
    Instance EqualTypes_Symmetric: Symmetric EqualTypes.
    Proof.
      unfold Symmetric.
      intros.
      destruct H.
      eapply InducedEq.
      exact H0.
      exact H.
    Qed.

    Fact InterSym { σ τ }: σ ∩ τ ≤ τ ∩ σ.
    Proof.
      apply (transitivity InterIdem).
      apply SubtyDistrib; auto.
    Qed.
    
    Fact Omega_eq: ω ~ ω.
    Proof.
      reflexivity.
    Qed.
    Hint Resolve Omega_eq.

    Fact Arrow_Tgt_Omega_eq {σ ρ : IntersectionType}:
      ω ~ ρ -> ω ~ σ → ρ.
    Proof.
      intro rhoOmega.
      split.
      - apply (transitivity OmegaArrow).
        apply CoContra.
        + exact OmegaTop.
        + exact rhoOmega.
      - exact OmegaTop.
    Qed.
    Hint Resolve Arrow_Tgt_Omega_eq.

    Fact Omega_Inter_Omega_eq {σ ρ : IntersectionType}:
       ω ~ σ -> ω ~ ρ -> ω ~ σ ∩ ρ.
    Proof.
      intros sigmaOmega rhoOmega.
      split.
      - apply (transitivity InterIdem).
        apply SubtyDistrib.
        + exact sigmaOmega.
        + exact rhoOmega.
      - exact OmegaTop.
    Qed.
    Hint Resolve Omega_Inter_Omega_eq.


    Section BetaLemmas.

      Reserved Notation "↑ω σ" (at level 89).
      Inductive Ω: IntersectionType -> Prop :=
        | OF_Omega : Ω ω
        | OF_Arrow : forall σ ρ, Ω ρ -> Ω (σ → ρ)
        | OF_Inter : forall σ ρ, Ω σ -> Ω ρ -> Ω (σ ∩ ρ)
      where "↑ω σ" := (Ω σ).   
            
      Fact Ω_principal: forall σ, ↑ω σ -> ω ~ σ.
      Proof.
        intros. 
        induction H; auto.
      Qed.

      Fact Ω_upperset:
        forall σ τ, σ ≤ τ -> ↑ω σ -> ↑ω τ.
      Proof.
        intros σ τ H.
        induction H; intro Hω; try solve [ inversion Hω; auto ].
        - apply OF_Inter; auto.
        - inversion Hω as [ | | * * σρω στω ].
          inversion σρω as [ | * * ρω | ].
          inversion στω as [ | * * τω | ].
          exact (OF_Arrow _ _ (OF_Inter _ _ ρω τω)).
        - inversion Hω as [ | | * * ωσ ωτ ].
          exact (OF_Inter _ _ (IHSubtypes1 ωσ) (IHSubtypes2 ωτ)).
        - inversion Hω as [ | * * ωτ | ].
          exact (OF_Arrow _ _ (IHSubtypes2 ωτ)).
        - exact OF_Omega.
        - exact (OF_Arrow _ _ OF_Omega).
        - exact Hω.
      Qed.

      Corollary Ω_principalElement:
        forall σ, ω ≤ σ -> ↑ω σ.
      Proof.
        intros σ ωLEσ.
        exact (Ω_upperset _ _ ωLEσ OF_Omega).
      Qed.
      
      Fact Ω_directed:
        forall σ τ, ↑ω σ -> ↑ω τ -> (↑ω ω) /\ (ω ≤ σ) /\ (ω ≤ τ).
      Proof.
        intros σ τ ωLEσ ωLEτ.
        split; [|split].
        - exact (OF_Omega).
        - exact (Ω_principal _ ωLEσ).
        - exact (Ω_principal _ ωLEτ).
      Qed.

      Fact Var_never_omega:
        forall n, ω ≤ Var n -> False.
      Proof.
        intros n ωLEn.
        set (ωn := Ω_upperset _ _ ωLEn OF_Omega).
        inversion ωn.
      Qed.

      Lemma Beta_Omega:
        forall σ τ, ω ~ σ → τ <-> ω ~ τ.
      Proof.
        intros.
        split.
        - intro στEQω.
          set (στω := Ω_upperset _ _ στEQω OF_Omega).
          inversion στω as [ | * * ωτ | ].
          exact (Ω_principal _ ωτ).
        - exact Arrow_Tgt_Omega_eq.
      Qed.

      Reserved Notation "↑α[ n ] σ " (at level 89).
      Inductive VariableFilter (n : nat): IntersectionType -> Prop :=
        | VF_Var : ↑α[n] (Var n)
        | VF_Omega : forall σ, σ ~ ω -> ↑α[n] σ
        | VF_Inter : forall σ τ, ↑α[n] σ -> ↑α[n] τ -> ↑α[n] σ ∩ τ
      where "↑α[ n ] σ" := (VariableFilter n σ).

      Fact VariableFilter_principal: 
        forall n σ, ↑α[n] σ -> (Var n) ≤ σ.
      Proof.
        induction σ; intro.
        - inversion H.
          + reflexivity.
          + contradict (Var_never_omega n0 (EqualTypesAreSubtypes_right _ _ H0)).
        - inversion H.
          transitivity ω .
          + exact OmegaTop.
          + exact (EqualTypesAreSubtypes_right _ _ H0).
        - inversion H.
          + transitivity ω.
            * exact OmegaTop.
            * exact (EqualTypesAreSubtypes_right _ _ H0).  
          + transitivity (Var n ∩ Var n).
            * exact (InterIdem).
            * exact (SubtyDistrib (IHσ1 H2) (IHσ2 H3)).
        - exact OmegaTop.
      Qed.

      Fact VariableFilter_upperset:
        forall σ τ, σ ≤ τ -> forall n, ↑α[n] σ -> ↑α[n] τ.
      Proof.
        intros σ τ σLEτ.
        induction σLEτ.
        - intros n H.
          inversion H.
          + apply (VF_Omega _ _).
            split.
            * exact OmegaTop.
            * transitivity (σ ∩ τ).
              { exact (EqualTypesAreSubtypes_right _ _ H0). }
              { exact InterMeetLeft. }
          + exact H2.
        - intros n H.
          inversion H.
          + apply (VF_Omega _ _).
            split.
            * exact OmegaTop.
            * transitivity (σ ∩ τ).
              { exact (EqualTypesAreSubtypes_right _ _ H0). }
              { exact InterMeetRight. }
          + exact H3.
        - intros n H.
          exact (VF_Inter _ _ _ H H).
        - intros n H.
          inversion H.
          + apply (VF_Omega _ _).
            split.
            * exact OmegaTop.
            * transitivity ((σ → ρ) ∩ (σ → τ)).
              { exact (EqualTypesAreSubtypes_right _ _ H0). } 
              { exact InterDistrib. }
          + inversion H2.
            inversion H3.
            apply (VF_Omega _ _).
            split.
            * exact OmegaTop.
            * transitivity (ω ∩ ω).
              { exact InterIdem. }
              { transitivity ((σ → ρ) ∩ (σ → τ)).
                - exact (SubtyDistrib (EqualTypesAreSubtypes_right _ _ H4) (EqualTypesAreSubtypes_right _ _ H6)).
                - exact InterDistrib. }
        - intros n H.
          inversion H.
          + apply (VF_Omega _ _).
            split.
            * exact OmegaTop.
            * transitivity (σ ∩ τ).
              { exact (EqualTypesAreSubtypes_right _ _ H0). }
              { exact (SubtyDistrib σLEτ1 σLEτ2). }
          + exact (VF_Inter _ _ _ (IHσLEτ1 n H2) (IHσLEτ2 n H3)).
        - intros n H.
          inversion H.
          apply (VF_Omega _ _).
          split.
          + exact OmegaTop.
          + transitivity (σ' → τ).
            * exact (EqualTypesAreSubtypes_right _ _ H0).
            * exact (CoContra σLEτ1 σLEτ2).
        - intros n H.
          exact (VF_Omega _ _ Omega_eq).
        - intros n H.
          apply (VF_Omega _ _).
          symmetry.
          exact (Arrow_Tgt_Omega_eq (Omega_eq)).
        - intros n H.
          exact H.
        - intros n H.
          exact (IHσLEτ2 n (IHσLEτ1 n H)).
      Qed.
      
      Corollary VariableFilter_principalElement:
        forall σ n, (Var n) ≤ σ -> ↑α[n] σ.
      Proof.
        intros σ n nLEσ.
        exact (VariableFilter_upperset _ _ nLEσ _ (VF_Var n)).
      Qed.
      
      Fact VariableFilter_directed:
        forall n σ τ, ↑α[n] σ -> ↑α[n] τ -> (↑α[n] (Var n)) /\ ((Var n) ≤ σ) /\ ((Var n) ≤ τ).
      Proof.
        intros n σ τ nLEσ nLEτ.
        split; [|split].
        - exact (VF_Var n).
        - exact (VariableFilter_principal _ _ nLEσ).
        - exact (VariableFilter_principal _ _ nLEτ).
      Qed.

      Reserved Notation "↓α[ n ] σ" (at level 89).
      Inductive VariableIdeal (n : nat): IntersectionType -> Prop :=
        | VI_Var : ↓α[n] (Var n)
        | VI_InterLeft : forall σ τ, ↓α[n] σ -> ↓α[n] σ ∩ τ
        | VI_InterRight : forall σ τ, ↓α[n] τ -> ↓α[n] σ ∩ τ
      where "↓α[ n ] σ" := (VariableIdeal n σ).

      Fact VariableIdeal_principal:
        forall n σ, ↓α[n] σ -> σ ≤ (Var n).
      Proof.
        intros n σ σLEn.
        induction σLEn.
        - reflexivity.
        - transitivity σ.
          + exact InterMeetLeft.
          + exact IHσLEn.
        - transitivity τ.
          + exact InterMeetRight.
          + exact IHσLEn.
      Qed.
      
      Fact VariableIdeal_lowerset:
        forall σ τ, σ ≤ τ -> forall n, ↓α[n] τ -> ↓α[n] σ.
      Proof.
        intros σ τ σLEτ.
        induction σLEτ;
          try solve [ intros n H; inversion H ].
        - exact (fun n => VI_InterLeft n _ _).
        - exact (fun n => VI_InterRight n _ _).
        - intros n H.
          inversion H; exact H1.
        - intros n H.
          inversion H.
          + exact (VI_InterLeft _ _ _ (IHσLEτ1 _ H1)).
          + exact (VI_InterRight _ _ _ (IHσLEτ2 _ H1)).
        - exact (fun n p => p).
        - intros n H.
          exact (IHσLEτ1 _ (IHσLEτ2 _ H)).
      Qed.
      
      Corollary VariableIdeal_principalElement:
        forall σ n, σ ≤ (Var n) -> ↓α[n] σ.
      Proof.
        intros σ n σLEn.
        exact (VariableIdeal_lowerset _ _ σLEn _ (VI_Var n)).
      Qed.
      
      Fact VariableIdeal_directed:
        forall n σ τ, ↓α[n] σ -> ↓α[n] τ -> (↓α[n] (Var n)) /\ (σ ≤ (Var n)) /\ (τ ≤ (Var n)).
      Proof.
        intros n σ τ σLEn τLEn.
        split; [|split].
        - exact (VI_Var n).
        - exact (VariableIdeal_principal _ _ σLEn).
        - exact (VariableIdeal_principal _ _ τLEn).
      Qed.

      Fact VariableIdeal_prime:
        forall σ τ n, ↓α[n] σ ∩ τ -> (↓α[n] σ) \/ (↓α[n] τ).
      Proof.
        intros σ τ n στLEn.
        inversion στLEn as [ | * * σLEn | * * τLEn ]; auto.
      Qed.


      Reserved Notation "↑[ σ ] → [ τ ] ρ" (at level 89).
      Inductive ArrowFilter (σ τ : IntersectionType): IntersectionType -> Prop :=
        | AF_Omega : forall ρ, Ω ρ -> ↑[σ] → [τ] ρ
        | AF_Arrow : forall σ' τ', σ' ≤ σ -> τ ≤ τ' -> ↑[σ] → [τ] σ' → τ'
        | AF_Inter : forall σ' τ' ρ1 ρ2,
            ↑[σ] → [ρ1] σ' -> ↑[σ] → [ρ2] τ' -> τ ≤ ρ1 ∩ ρ2 -> ↑[σ] → [τ] σ' ∩ τ'
      where "↑[ σ ] → [ τ ] ρ" := (ArrowFilter σ τ ρ).
      
      Fact ArrowFilter_principal:
        forall σ τ ρ, ↑[σ] → [τ] ρ -> σ → τ ≤ ρ.
      Proof.
        intros σ τ ρ στLEρ.
        induction στLEρ.
        - transitivity ω.
          + exact OmegaTop.
          + exact (Ω_principal _ H).
        - exact (CoContra H H0).
        - transitivity ((σ → τ) ∩ (σ → τ)).
          + exact InterIdem.
          + apply SubtyDistrib.
            * transitivity (σ → ρ1).
              { apply CoContra.
                - reflexivity.
                - transitivity (ρ1 ∩ ρ2).
                  + exact H.
                  + exact InterMeetLeft. }
              { exact IHστLEρ1. }
            * transitivity (σ → ρ2).  
              { apply CoContra.
                - reflexivity.
                - transitivity (ρ1 ∩ ρ2).
                  + exact H.
                  + exact InterMeetRight. }
              { exact IHστLEρ2. }
      Qed.

      Fact ArrowFilter_weaken:
        forall σ τ ρ, ↑[σ] → [τ] ρ -> forall τ', τ' ≤ τ -> ↑[σ] → [τ'] ρ.
      Proof.
        intros σ τ ρ στLEρ.
        induction στLEρ; intros τ'' τ''LEτ.
        - exact (AF_Omega _ _ _ H).
        - apply (AF_Arrow _ _ _).
          + exact H.
          + transitivity τ.
            * exact τ''LEτ.
            * exact H0. 
        - apply (AF_Inter _ _ _ _ τ τ).
          + apply (IHστLEρ1 _).
            transitivity (ρ1 ∩ ρ2).
            * exact H.
            * exact InterMeetLeft.
          + apply (IHστLEρ2 _).
            transitivity (ρ1 ∩ ρ2).
            * exact H.
            * exact InterMeetRight.
          + transitivity τ.
            * exact τ''LEτ.
            * exact InterIdem. 
      Qed.

      Fact ArrowFilter_upperset:
        forall ρ1 ρ2, ρ1 ≤ ρ2 -> forall σ τ, ↑[σ] → [τ] ρ1 -> ↑[σ] → [τ] ρ2.
      Proof.
        intros ρ1 ρ2 ρ1LEρ2.
        induction ρ1LEρ2; intros σ0 τ0 H.
        - inversion H.
          + apply (AF_Omega).
            exact (Ω_upperset (σ ∩ τ) σ InterMeetLeft H0).
          + apply (ArrowFilter_weaken _ _ _ H2).
            transitivity (ρ1 ∩ ρ2).
            * exact H4.
            * exact InterMeetLeft.
        - inversion H.
          + apply (AF_Omega).
            exact (Ω_upperset (σ ∩ τ) τ InterMeetRight H0).
          + apply (ArrowFilter_weaken _ _ _ H3).
            transitivity (ρ1 ∩ ρ2).
            * exact H4.
            * exact InterMeetRight.
        - apply (AF_Inter _ _ _ _ _ _ H H).
          exact InterIdem.
        - inversion H.
          + apply AF_Omega.
            exact (Ω_upperset _ _ InterDistrib H0).
          + inversion H2; inversion H3.
            * apply AF_Omega.
              exact (Ω_upperset _ _ InterDistrib (OF_Inter _ _ H5 H7)).
            * apply AF_Arrow.
              { exact H9. }
              { transitivity (τ0 ∩ τ0).
                - exact InterIdem.
                - apply SubtyDistrib.
                  + transitivity ω.
                    * exact OmegaTop.
                    * exact ((proj1 (Beta_Omega _ _)) (Ω_principal _ H5)).
                  + transitivity ρ2.
                    * transitivity (ρ1 ∩ ρ2).
                      { exact H4. }
                      { exact InterMeetRight. } 
                    * exact H10. } 
            * apply AF_Arrow.
              { exact H7. }
              { transitivity (τ0 ∩ τ0).
                - exact InterIdem.
                - apply SubtyDistrib.
                  + transitivity ρ1.
                    * transitivity (ρ1 ∩ ρ2).
                      { exact H4. }
                      { exact InterMeetLeft. } 
                    * exact H8.
                  + transitivity ω.
                    * exact OmegaTop.
                    * exact ((proj1 (Beta_Omega _ _)) (Ω_principal _ H9)). }
            * apply AF_Arrow.
              { exact H7. }
              { transitivity (ρ1 ∩ ρ2).
                - exact H4. 
                - apply SubtyDistrib.
                  + exact H8.
                  + exact H12. }
        - inversion H.
          + apply AF_Omega.
            exact (Ω_upperset _ _ (SubtyDistrib ρ1LEρ2_1 ρ1LEρ2_2) H0).
          + apply (AF_Inter _ _ _ _ τ0 τ0).
            * apply (ArrowFilter_weaken _ ρ1 _).
              { exact (IHρ1LEρ2_1 _ _ H2). }
              { transitivity (ρ1 ∩ ρ2).
                - exact H4.
                - exact InterMeetLeft. }
            * apply (ArrowFilter_weaken _ ρ2 _).
              { exact (IHρ1LEρ2_2 _ _ H3). }
              { transitivity (ρ1 ∩ ρ2).
                - exact H4.
                - exact InterMeetRight. }
            * exact InterIdem.
        - inversion H.
          + apply AF_Omega.
            exact (Ω_upperset _ _ (CoContra ρ1LEρ2_1 ρ1LEρ2_2) H0).
          + apply (AF_Arrow).
            * transitivity σ'.
              { exact ρ1LEρ2_1. }
              { exact H2. }
            * transitivity τ.
              { exact H3. }
              { exact ρ1LEρ2_2. }
        - exact (AF_Omega _ _ _ OF_Omega).
        - exact (AF_Omega _ _ _ (OF_Arrow _  _ OF_Omega)).
        - exact H.
        - exact (IHρ1LEρ2_2 _ _ (IHρ1LEρ2_1 _ _ H)).
      Qed.

      Corollary ArrowFilter_principalElement:
        forall ρ σ τ, σ → τ ≤ ρ -> ↑[σ] → [τ] ρ.
      Proof.
        intros ρ σ τ στLEρ.
        exact (ArrowFilter_upperset _ _ στLEρ _ _
                (AF_Arrow _ _ _ _ (reflexivity σ) (reflexivity τ))).
      Qed.
      
      Fact ArrowFilter_directed:
        forall ρ1 ρ2 σ τ, ↑[σ] → [τ] ρ1 -> ↑[σ] → [τ] ρ2 ->
        (↑[σ] → [τ] σ → τ) /\ (σ → τ ≤ ρ1) /\ (σ → τ ≤ ρ2).
      Proof.
        intros ρ1 ρ2 σ τ στLEρ1 στLEρ2.
        split; [|split].
        - exact (AF_Arrow _ _ _ _ (reflexivity σ) (reflexivity τ)).
        - exact (ArrowFilter_principal _ _ _ στLEρ1).
        - exact (ArrowFilter_principal _ _ _ στLEρ2).
      Qed.

      Reserved Notation "↓[ σ ] → [ τ ] ρ" (at level 89).
      Inductive ArrowIdeal (σ τ : IntersectionType): IntersectionType -> Prop :=
        | AI_Omega : forall ρ, ↑ω τ -> ↓[σ] → [τ] ρ
        | AI_Arrow : forall σ' τ', σ ≤ σ' -> τ' ≤ τ -> ↓[σ] → [τ] σ' → τ'
        | AI_InterLeft : forall σ' τ', ↓[σ] → [τ] σ' -> ↓[σ] → [τ] σ' ∩ τ'
        | AI_InterRight : forall σ' τ', ↓[σ] → [τ] τ' -> ↓[σ] → [τ] σ' ∩ τ'
        | AI_Inter : forall σ' τ' ρ1 ρ2,
            ↓[σ] → [ρ1] σ' -> ↓[σ] → [ρ2] τ' -> ρ1 ∩ ρ2 ≤ τ -> ↓[σ] → [τ] σ' ∩ τ'
      where "↓[ σ ] → [ τ ] ρ" := (ArrowIdeal σ τ ρ).

      Hint Resolve AI_Omega AI_Arrow AI_InterLeft AI_InterRight. 

      Fact ArrowIdeal_principal:
        forall σ τ ρ, ↓[σ] → [τ] ρ -> ρ ≤ σ → τ.
      Proof.
        intros σ τ ρ ρLEστ.
        induction ρLEστ.
        - transitivity ω.
          + exact OmegaTop.
          + exact (Ω_principal _ (OF_Arrow _ _ H)).
        - exact (CoContra H H0).
        - transitivity σ'.
          + exact InterMeetLeft.
          + exact IHρLEστ.
        - transitivity τ'.
          + exact InterMeetRight.
          + exact IHρLEστ.
        - transitivity ((σ → ρ1) ∩ (σ → ρ2)).
          + exact (SubtyDistrib IHρLEστ1 IHρLEστ2).
          + transitivity (σ → ρ1 ∩ ρ2).
            * exact InterDistrib.
            * apply CoContra.
              { reflexivity. } 
              { exact H. }
      Qed.

      Fact ArrowIdeal_weaken:
        forall σ τ ρ, ↓[σ] → [τ] ρ -> forall τ', τ ≤ τ' -> ↓[σ] → [τ'] ρ.
      Proof.
        intros σ τ ρ ρLEστ.
        induction ρLEστ; intros τ'' τLEτ''.
        - set (H' := Ω_upperset _ _ τLEτ'' H).
          auto.
        - set (H0' := transitivity H0 τLEτ'').
          auto.
        - set (IHρLEστ' := IHρLEστ τ'' τLEτ''). 
          auto.
        - set (IHρLEστ' := IHρLEστ τ'' τLEτ''). 
          auto.
        - set (IHρLEστ1' := IHρLEστ1 ρ1 (reflexivity _)).
          set (IHρLEστ2' := IHρLEστ2 ρ2 (reflexivity _)).
          set (ρ1ρ2LEτ'' := transitivity H τLEτ'').
          exact (AI_Inter _ _ _ _ _ _ IHρLEστ1' IHρLEστ2' ρ1ρ2LEτ'').
      Qed.

      Fact ArrowIdeal_both:
        forall τ ρ1 ρ2 σ, ↓[σ] → [ρ1] τ -> ↓[σ] → [ρ2] τ -> ↓[σ] → [ρ1 ∩ ρ2] τ.
      Proof.
        intro τ.
        induction τ;
          intros ρ1 ρ2 σ H1 H2;
          inversion H1;
          try solve [
            set (ρ1ω := Ω_principal _ H);
            assert (ρ2LEρ1ρ2 : ρ2 ≤ ρ1 ∩ ρ2);
            solve [
              apply (transitivity InterIdem);
              apply SubtyDistrib;
              solve [
                transitivity ω; solve [ auto | exact ρ1ω ]
                |  reflexivity ]
            | exact (ArrowIdeal_weaken _ _ _ H2 _ ρ2LEρ1ρ2) ] ];
          inversion H2 as [ * ωρ2 ρeq  |  |  |  |  ];
          try solve [
            set (ρ2ω := Ω_principal _ ωρ2);
            assert (ρ1LEρ1ρ2 : ρ1 ≤ ρ1 ∩ ρ2);
            solve [
              apply (transitivity InterIdem);
              apply SubtyDistrib;
              solve [
                reflexivity
                | transitivity ω; solve [ auto | exact ρ2ω ] ]
            | exact (ArrowIdeal_weaken _ _ _ H1 _ ρ1LEρ1ρ2) ] ].
        - apply AI_Arrow.
          + auto.
          + apply (transitivity InterIdem).
            apply SubtyDistrib.
            * auto.
            * auto. 
        - apply AI_InterLeft.
          apply IHτ1; auto.
        - apply (AI_Inter _ _ _ _ ρ1 ρ2); auto;
          reflexivity.
        - apply (AI_Inter _ _ _ _ (ρ0 ∩ ρ1) ρ3).
          + apply IHτ1; auto.
          + auto.
          + transitivity (ρ1 ∩ ρ0 ∩ ρ3).
            * transitivity ((ρ1 ∩ ρ0) ∩ ρ3).
              { apply SubtyDistrib.
                - apply InterSym.
                - reflexivity. }
              { apply (transitivity InterIdem).
                apply SubtyDistrib.
                - apply (transitivity InterMeetLeft).
                  auto.
                - apply SubtyDistrib.
                  + auto.
                  + reflexivity. }
            * apply SubtyDistrib.
              { reflexivity. }
              { auto. }
       - apply (AI_Inter _ _ _ _ ρ2 ρ1); auto.
         exact (InterSym).
       - apply AI_InterRight.
         apply IHτ2; auto.
       - apply (AI_Inter _ _ _ _ ρ0 (ρ1 ∩ ρ3)).
          + auto.
          + apply IHτ2; auto.
          + transitivity (ρ1 ∩ ρ0 ∩ ρ3).
            * apply (transitivity InterIdem).
              apply SubtyDistrib.
              { apply (transitivity InterMeetRight).
                auto. }
              { apply SubtyDistrib.
                reflexivity.
                auto. }
            * apply SubtyDistrib.
              { reflexivity. }
              { auto. }
       - apply (AI_Inter _ _ _ _ (ρ0 ∩ ρ2) ρ3).
          + apply IHτ1; auto.
          + auto.
          + transitivity ((ρ0 ∩ ρ3) ∩ ρ2).
            * apply (transitivity InterIdem).
              apply SubtyDistrib.
              { apply (SubtyDistrib).
                - auto.
                - reflexivity. }
              { apply (transitivity InterMeetLeft).
                auto. }
            * apply SubtyDistrib.
              { auto. }
              { reflexivity. }
       - apply (AI_Inter _ _ _ _ ρ0 (ρ2 ∩ ρ3)).
          + auto.
          + apply IHτ2; auto.
          + transitivity ((ρ0 ∩ ρ3) ∩ ρ2).
            * apply (transitivity InterIdem).
              apply SubtyDistrib.
              { apply (SubtyDistrib).
                - reflexivity.
                - auto. }
              { apply (transitivity InterMeetRight).
                auto. }
            * apply SubtyDistrib.
              { auto. }
              { reflexivity. }
       - apply (AI_Inter _ _ _ _ (ρ0 ∩ ρ4) (ρ3 ∩ ρ5)).
          + apply IHτ1; auto.
          + apply IHτ2; auto.
          + transitivity ((ρ0 ∩ ρ3) ∩ ρ4 ∩ ρ5).
            * apply (transitivity InterIdem).
              apply SubtyDistrib;
                apply (SubtyDistrib); auto.
            * apply SubtyDistrib; auto.
      Qed.

      Fact ArrowIdeal_lowerset:
        forall ρ1 ρ2, ρ1 ≤ ρ2 -> forall σ τ, ↓[σ] → [τ] ρ2 -> ↓[σ] → [τ] ρ1.
      Proof.
        intros ρ1 ρ2 ρ1LEρ2.
        induction ρ1LEρ2; 
          try solve [ auto ];
          intros σ'' τ'' H;
          inversion H;
          auto.
        - exact (ArrowIdeal_weaken _ _ _ (ArrowIdeal_both _ _ _ _ H2 H3) _ H4).
        - apply (AI_Inter _ _ _ _ ρ τ).
          + exact (AI_Arrow _ _ _ _ H2 (reflexivity ρ)).
          + exact (AI_Arrow _ _ _ _ H2 (reflexivity τ)). 
          + exact H3.
        - apply (AI_Inter _ _ _ _ ρ1 ρ2).
          + exact (IHρ1LEρ2_1 _ _ H2).
          + exact (IHρ1LEρ2_2 _ _ H3).
          + exact H4.
        - apply AI_Arrow.
          + exact (transitivity H2 ρ1LEρ2_1).
          + exact (transitivity ρ1LEρ2_2 H3).
        - set (ωτ := Ω_upperset _ _ H3 OF_Omega).
          auto.
      Qed.
      
      Corollary ArrowIdeal_principalElement:
        forall ρ σ τ, ρ ≤ σ → τ -> ↓[σ] → [τ] ρ.
      Proof.
        intros ρ σ τ ρLEστ.
        exact (ArrowIdeal_lowerset _ _ ρLEστ _ _ 
          (AI_Arrow _ _ _ _ (reflexivity σ) (reflexivity τ))).
      Qed.
      
      Fact ArrowIdeal_directed:
        forall ρ1 ρ2 σ τ, ↓[σ] → [τ] ρ1 -> ↓[σ] → [τ] ρ2 ->
        (↓[σ] → [τ] σ → τ) /\ (ρ1 ≤ σ → τ) /\ (ρ2 ≤ σ → τ).
      Proof.
        intros ρ1 ρ2 σ τ ρ1LEστ ρ2LEστ.
        split; [|split].
        - exact (AI_Arrow _ _ _ _ (reflexivity σ) (reflexivity τ)).
        - exact (ArrowIdeal_principal _ _ _ ρ1LEστ).
        - exact (ArrowIdeal_principal _ _ _ ρ2LEστ).
      Qed.

      Fact ArrowIdeal_prime:
        forall ρ1 ρ2 σ τ,
          ↓[σ] → [τ] ρ1 ∩ ρ2 ->
          (((↓[σ] → [τ] ρ1) \/ (ρ2 ≤ ρ1)) \/
           ((↓[σ] → [τ] ρ2) \/ (ρ1 ≤ ρ2)) <->
           (↓[σ] → [τ] ρ1) \/ (↓[σ] → [τ] ρ2)).
      Proof.
        intros ρ1 ρ2 σ τ ρ1ρ2LEστ.
        split.
        - intros ρ1ORρ2.
          destruct ρ1ORρ2 as [ [ ρ1LEστ | ρ2LEρ1 ] | [ ρ2LEστ | ρ1LEρ2 ] ];
            inversion ρ1ρ2LEστ;
            auto.
          + right.
            apply (ArrowIdeal_lowerset ρ2 (ρ1 ∩ ρ2)).
            * apply (transitivity InterIdem).
              apply SubtyDistrib.
              { exact ρ2LEρ1. }
              { reflexivity. }
            * exact ρ1ρ2LEστ.
          + left.
            apply (ArrowIdeal_lowerset ρ1 (ρ1 ∩ ρ2)).
            * apply (transitivity InterIdem).
              apply SubtyDistrib.
              { reflexivity. }
              { exact ρ1LEρ2. }
            * exact ρ1ρ2LEστ.
        - intro primality.
          destruct primality as [ ρ1LEστ | ρ2LEστ ].
          + left; auto.
          + right; auto.
      Qed.
            


      Print ArrowLowerset_both.

      Definition ArrowSelection (ρ σ τ: IntersectionType): Prop :=
        let fix sel (ρ : IntersectionType) 
                (contAdd : Prop -> IntersectionType -> Prop)
                (contSkip : Prop): Prop :=
          match ρ with
            | Arr σ' τ' => contAdd (σ ≤ σ') τ'
            | Inter σ' τ' => 
                sel τ' (fun σsel τsel => 
                  sel σ' (fun σsel' τsel' => 
                      contAdd (σsel' /\ σsel) (τsel' ∩ τsel))
                    (contAdd σsel τsel))
                  (sel σ' contAdd contSkip)
            | _ => contSkip
            end in
        sel ρ (fun σsel τsel => σsel /\ (τsel ≤ τ)) (False).
      
      Definition Beta_Arrows:
        forall ρ σ τ, ρ ≤ σ → τ -> ArrowSelection ρ σ τ.
      Proof.
        induction ρ.
        Focus 3.
        - intros σ τ ρLEστ.
          inversion ρLEστ.
          rewrite <- H0 in H.
          inversion H; inversion H2;
            try solve [ rewrite <- H4 in H0 || rewrite <- H6 in H0 || rewrite H2 in H0; discriminate H0 ].
          + 
           
        induction ρLEστ.
        - 


  End SubtypeRelation.


End Types.

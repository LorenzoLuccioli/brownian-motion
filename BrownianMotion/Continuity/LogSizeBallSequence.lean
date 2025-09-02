/-
Copyright (c) 2025 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
import Mathlib.Order.CompletePartialOrder

/-!
# TODO

-/

open scoped ENNReal NNReal Finset

variable {T : Type*} [PseudoEMetricSpace T] {a c : ℝ≥0∞} {n : ℕ} {V : Finset T} {t : T}

lemma exists_radius_le (t : T) (V : Finset T) (ha : 1 < a) (c : ℝ≥0∞) :
    ∃ r : ℕ, 1 ≤ r ∧ #(V.filter fun x ↦ edist t x ≤ r * c) ≤ a ^ r := by
  obtain ⟨r, hr1, hr⟩ : ∃ r : ℕ, 1 ≤ r ∧ #V ≤ a ^ r := by
    use ⌈Real.logb (a.toReal) #V⌉₊ + 1, by simp
    by_cases h1 : a = ∞
    · simp [h1]
    by_cases h2 : #V = 0
    · simp [h2]
    rw [← ENNReal.toReal_le_toReal, ← ENNReal.rpow_natCast, ← ENNReal.toReal_rpow,
      ← Real.logb_le_iff_le_rpow]
    · apply le_trans (Nat.le_ceil _); simp
    · rw [← ENNReal.toReal_one]; gcongr; simp [h1]
    · simp [← Finset.card_ne_zero, h2]
    · apply (ENNReal.top_ne_natCast _).symm
    · apply ENNReal.pow_ne_top h1
  exact ⟨r, hr1, le_trans (mod_cast Finset.card_filter_le V _) hr⟩

open Classical in
noncomputable
def logSizeRadius (t : T) (V : Finset T) (a c : ℝ≥0∞) : ℕ :=
  if h : 1 < a then Nat.find (exists_radius_le t V h c) else 0

lemma one_le_logSizeRadius (ha : 1 < a) : 1 ≤ logSizeRadius t V a c := by
  rw [logSizeRadius, dif_pos ha]
  exact (Nat.find_spec (exists_radius_le t V ha c)).1

lemma card_le_logSizeRadius_le (ha : 1 < a) :
    #(V.filter fun x ↦ edist t x ≤ logSizeRadius t V a c * c) ≤ a ^ (logSizeRadius t V a c) := by
  rw [logSizeRadius, dif_pos ha]
  exact (Nat.find_spec (exists_radius_le t V ha c)).2

lemma card_le_logSizeRadius_ge (ha : 1 < a) (ht : t ∈ V) :
    a ^ (logSizeRadius t V a c - 1)
      ≤ #(V.filter fun x ↦ edist t x ≤ (logSizeRadius t V a c - 1) * c) := by
  by_cases h_one : logSizeRadius t V a c = 1
  · simp only [h_one, tsub_self, pow_zero, Nat.cast_one, zero_mul, nonpos_iff_eq_zero,
      Nat.one_le_cast, Finset.one_le_card]
    refine ⟨t, ?_⟩
    simp [ht]
  rw [logSizeRadius, dif_pos ha] at h_one ⊢
  have : Nat.find (exists_radius_le t V ha c) - 1 < Nat.find (exists_radius_le t V ha c) := by
    simp
  have h := Nat.find_min (exists_radius_le t V ha c) this
  simp only [ENNReal.natCast_sub, Nat.cast_one, not_and, not_le] at h
  refine (h ?_).le
  omega

structure logSizeBallStruct (T : Type*) where
  finset : Finset T
  point : T
  radius : ℕ

noncomputable
def logSizeBallStruct.smallBall (struct : logSizeBallStruct T) (c : ℝ≥0∞) :
    Finset T :=
  struct.finset.filter fun x ↦ edist struct.point x ≤ (struct.radius - 1) * c

noncomputable
def logSizeBallStruct.ball (struct : logSizeBallStruct T) (c : ℝ≥0∞) :
    Finset T :=
  struct.finset.filter fun x ↦ edist struct.point x ≤ struct.radius * c

open Classical in
noncomputable
def logSizeBallSeq (J : Finset T) (hJ : J.Nonempty) (a c : ℝ≥0∞) : ℕ → logSizeBallStruct T :=
  Nat.rec ({finset := J, point := hJ.choose, radius := logSizeRadius hJ.choose J a c})
    (fun _ struct ↦
      let V' := struct.finset \ struct.smallBall c
      let t' := if hV' : V'.Nonempty then hV'.choose else struct.point
      { finset := V',
        point := t',
        radius := logSizeRadius t' V' a c })

variable {J : Finset T}

lemma finset_logSizeBallSeq_zero (hJ : J.Nonempty) :
    (logSizeBallSeq J hJ a c 0).finset = J := rfl

lemma point_logSizeBallSeq_zero (hJ : J.Nonempty) :
    (logSizeBallSeq J hJ a c 0).point = hJ.choose := rfl

lemma radius_logSizeBallSeq_zero (hJ : J.Nonempty) :
    (logSizeBallSeq J hJ a c 0).radius = logSizeRadius hJ.choose J a c := rfl

open Classical in
lemma finset_logSizeBallSeq_add_one (hJ : J.Nonempty) (i : ℕ) :
    (logSizeBallSeq J hJ a c (i + 1)).finset =
      (logSizeBallSeq J hJ a c i).finset \ (logSizeBallSeq J hJ a c i).smallBall c := rfl

open Classical in
lemma point_logSizeBallSeq_add_one (hJ : J.Nonempty) (i : ℕ) :
    (logSizeBallSeq J hJ a c (i + 1)).point
      = if hV' : (logSizeBallSeq J hJ a c (i + 1)).finset.Nonempty then hV'.choose
        else (logSizeBallSeq J hJ a c i).point := rfl

lemma radius_logSizeBallSeq_add_one (hJ : J.Nonempty) (i : ℕ) :
    (logSizeBallSeq J hJ a c (i + 1)).radius
      = logSizeRadius (logSizeBallSeq J hJ a c (i + 1)).point
          (logSizeBallSeq J hJ a c (i + 1)).finset a c := rfl

lemma finset_logSizeBallSeq_add_one_subset (hJ : J.Nonempty) (i : ℕ) :
    (logSizeBallSeq J hJ a c (i + 1)).finset ⊆ (logSizeBallSeq J hJ a c i).finset := by
  simp [finset_logSizeBallSeq_add_one]

lemma antitone_logSizeBallSeq_add_one_subset (hJ : J.Nonempty) :
    Antitone (fun i ↦ (logSizeBallSeq J hJ a c i).finset) :=
  antitone_nat_of_succ_le (finset_logSizeBallSeq_add_one_subset hJ)

lemma radius_logSizeBallSeq_le (hJ : J.Nonempty) (ha : 1 < a) (hn : 1 ≤ n) (hJ_card : #J ≤ a ^ n)
    (i : ℕ) : (logSizeBallSeq J hJ a c i).radius ≤ n := by
  match i with
  | 0 =>
      simp only [radius_logSizeBallSeq_zero, logSizeRadius, ha, ↓reduceDIte]
      exact Nat.find_min' _ ⟨hn, le_trans (by gcongr; apply Finset.filter_subset) hJ_card⟩
  | i + 1 =>
      simp only [radius_logSizeBallSeq_add_one, logSizeRadius, ha, ↓reduceDIte]
      refine Nat.find_min' _ ⟨hn, le_trans ?_ hJ_card⟩
      gcongr
      apply subset_trans (Finset.filter_subset _ _)
      apply subset_trans <| (antitone_logSizeBallSeq_add_one_subset hJ) (zero_le (i + 1))
      simp [finset_logSizeBallSeq_zero]

lemma one_le_radius_logSizeBallSeq (hJ : J.Nonempty) (ha : 1 < a) (i : ℕ) :
    1 ≤ (logSizeBallSeq J hJ a c i).radius := by
  match i with
  | 0 => simpa [radius_logSizeBallSeq_zero] using one_le_logSizeRadius ha
  | i + 1 => simpa [radius_logSizeBallSeq_add_one] using one_le_logSizeRadius ha

lemma point_mem_finset_logSizeBallSeq (hJ : J.Nonempty) (i : ℕ)
    (h : (logSizeBallSeq J hJ a c i).finset.Nonempty) :
    (logSizeBallSeq J hJ a c i).point ∈ (logSizeBallSeq J hJ a c i).finset := by
  match i with
  | 0 => simp [point_logSizeBallSeq_zero, finset_logSizeBallSeq_zero, Exists.choose_spec]
  | i + 1 => simp [point_logSizeBallSeq_add_one, h, Exists.choose_spec]

lemma point_mem_logSizeBallSeq_zero (hJ : J.Nonempty) (i : ℕ) :
    (logSizeBallSeq J hJ a c i).point ∈ J := by
  induction i with
  | zero =>
      apply point_mem_finset_logSizeBallSeq hJ 0
      rwa [finset_logSizeBallSeq_zero]
  | succ i ih =>
      by_cases h : (logSizeBallSeq J hJ a c (i + 1)).finset.Nonempty
      · refine Finset.mem_of_subset ?_ (point_mem_finset_logSizeBallSeq hJ (i + 1) h)
        apply subset_trans <| (antitone_logSizeBallSeq_add_one_subset hJ) (zero_le (i + 1))
        simp [finset_logSizeBallSeq_zero]
      simp [point_logSizeBallSeq_add_one, ih, h]

lemma point_notMem_finset_logSizeBallSeq_add_one (hJ : J.Nonempty) (i : ℕ) :
    (logSizeBallSeq J hJ a c i).point ∉ (logSizeBallSeq J hJ a c (i + 1)).finset := by
  simp [finset_logSizeBallSeq_add_one, logSizeBallStruct.smallBall]

lemma finset_logSizeBallSeq_add_one_ssubset (hJ : J.Nonempty) (i : ℕ)
    (h : (logSizeBallSeq J hJ a c i).finset.Nonempty) :
    (logSizeBallSeq J hJ a c (i + 1)).finset ⊂ (logSizeBallSeq J hJ a c i).finset := by
    apply ssubset_of_subset_not_subset
    · simp [finset_logSizeBallSeq_add_one]
    refine Set.not_subset.mpr ⟨(logSizeBallSeq J hJ a c i).point, ?_, ?_⟩
    · exact point_mem_finset_logSizeBallSeq hJ i h
    exact point_notMem_finset_logSizeBallSeq_add_one hJ i

lemma card_finset_logSizeBallSeq_add_one_lt (hJ : J.Nonempty) (i : ℕ)
    (h : (logSizeBallSeq J hJ a c i).finset.Nonempty) :
    #(logSizeBallSeq J hJ a c (i + 1)).finset < #(logSizeBallSeq J hJ a c i).finset := by
  simp [Finset.card_lt_card, finset_logSizeBallSeq_add_one_ssubset hJ i h]

lemma card_finset_logSizeBallSeq_le (hJ : J.Nonempty) (i : ℕ) :
    #(logSizeBallSeq J hJ a c i).finset ≤ #J - i := by
  induction i with
  | zero => simp [finset_logSizeBallSeq_zero]
  | succ i ih =>
      by_cases h : (logSizeBallSeq J hJ a c i).finset.Nonempty
      · apply Nat.le_of_lt_succ
        apply lt_of_lt_of_le (card_finset_logSizeBallSeq_add_one_lt hJ i h)
        omega
      apply le_trans <| Finset.card_le_card (finset_logSizeBallSeq_add_one_subset hJ i)
      suffices #(logSizeBallSeq J hJ a c i).finset = 0 by simp [this]
      rw [← Finset.card_empty]
      congr
      exact Finset.not_nonempty_iff_eq_empty.mp h

lemma card_finset_logSizeBallSeq_card_eq_zero (hJ : J.Nonempty) :
    #(logSizeBallSeq J hJ a c #J).finset = 0 := by
  rw [← Nat.le_zero,← tsub_self #J]
  exact card_finset_logSizeBallSeq_le hJ #J

lemma disjoint_smallBall_logSizeBallSeq (hJ : J.Nonempty) {i j : ℕ} (hij : i ≠ j) :
    Disjoint
      ((logSizeBallSeq J hJ a c i).smallBall c) ((logSizeBallSeq J hJ a c j).smallBall c) := by
  wlog h : i < j generalizing i j
  · exact Disjoint.symm <| this hij.symm <| (ne_iff_lt_iff_le.mpr (not_lt.mp h)).mp hij.symm
  apply Finset.disjoint_of_subset_right
  · exact subset_trans (Finset.filter_subset _ _) (antitone_logSizeBallSeq_add_one_subset hJ h)
  simp [finset_logSizeBallSeq_add_one, Finset.disjoint_sdiff]

open Classical in
noncomputable
def pairSetSeq (J : Finset T) (a c : ℝ≥0∞) (n : ℕ) : Finset (T × T) :=
  if hJ : J.Nonempty then
    Finset.product {(logSizeBallSeq J hJ a c n).point} ((logSizeBallSeq J hJ a c n).ball c)
  else ∅

open Classical in
noncomputable
def pairSet (J : Finset T) (a c : ℝ≥0∞) : Finset (T × T) :=
  Finset.biUnion (Finset.range #J) (pairSetSeq J a c)

open Classical in
lemma pairSet_subset : pairSet J a c ⊆ J.product J := by
  unfold pairSet
  rw [Finset.biUnion_subset_iff_forall_subset]
  intro i hi
  by_cases hJ : J.Nonempty
  · simp only [pairSetSeq, hJ, ↓reduceDIte]
    apply Finset.product_subset_product
    · apply Finset.singleton_subset_iff.mpr (point_mem_logSizeBallSeq_zero hJ _)
    apply subset_trans
    · apply subset_trans (Finset.filter_subset _ _)
      exact antitone_logSizeBallSeq_add_one_subset hJ (zero_le _)
    simp [finset_logSizeBallSeq_zero]
  simp [pairSetSeq, hJ]

lemma card_pairSetSeq_le_logSizeRadius (hJ : J.Nonempty) (i : ℕ) (ha : 1 < a) :
    ↑(#(pairSetSeq J a c i)) ≤ (if (logSizeBallSeq J hJ a c i).finset.Nonempty then 1 else 0)
    * a ^ (logSizeBallSeq J hJ a c i).radius := by
  induction i with
  | zero =>
      simp only [pairSetSeq, hJ, ↓reduceDIte, logSizeBallStruct.ball, radius_logSizeBallSeq_zero,
        finset_logSizeBallSeq_zero, Finset.product_eq_sprod, Finset.singleton_product,
        Finset.card_map, ↓reduceIte, one_mul]
      exact card_le_logSizeRadius_le ha
  | succ i ih =>
      by_cases h : (logSizeBallSeq J hJ a c (i + 1)).finset.Nonempty
      · simp only [pairSetSeq, hJ, ↓reduceDIte, logSizeBallStruct.ball, Finset.product_eq_sprod,
          Finset.singleton_product, Finset.card_map, h, ↓reduceIte, one_mul]
        exact card_le_logSizeRadius_le ha
      simp [pairSetSeq, logSizeBallStruct.ball, Finset.not_nonempty_iff_eq_empty.mp h, hJ]

open Classical in
lemma logSizeRadius_le_card_smallBall (hJ : J.Nonempty) (i : ℕ) (ha : 1 < a) :
    (if (logSizeBallSeq J hJ a c i).finset.Nonempty then 1 else 0) *
    a ^ ((logSizeBallSeq J hJ a c i).radius - 1) ≤ #((logSizeBallSeq J hJ a c i).smallBall c) := by
  match i with
  | 0 =>
      simp only [finset_logSizeBallSeq_zero, hJ, ↓reduceIte, radius_logSizeBallSeq_zero, one_mul,
        logSizeBallStruct.smallBall, ge_iff_le]
      exact card_le_logSizeRadius_ge ha (Exists.choose_spec hJ)
  | i + 1 =>
      by_cases h : (logSizeBallSeq J hJ a c (i + 1)).finset.Nonempty
      · simp only [h, ↓reduceIte, radius_logSizeBallSeq_add_one, one_mul,
          logSizeBallStruct.smallBall, ge_iff_le]
        exact card_le_logSizeRadius_ge ha (point_mem_finset_logSizeBallSeq hJ _ h)
      simp [Finset.not_nonempty_iff_eq_empty.mp h]

open Classical in
lemma card_pairSet_le (ha : 1 < a) (hJ_card : #J ≤ a ^ n) :
    #(pairSet J a c) ≤ a * #J := by
  wlog hJ : J.Nonempty
  · convert zero_le (a * ↑(#J))
    rw [← Nat.cast_zero]
    congr
    rw [Finset.card_eq_zero]
    refine subset_antisymm ?_ (Finset.empty_subset _)
    convert pairSet_subset
    simp [Finset.not_nonempty_iff_eq_empty.mp hJ]
  apply le_trans (Nat.mono_cast Finset.card_biUnion_le)
  rw [Nat.cast_sum]
  apply le_trans (Finset.sum_le_sum (fun i _ ↦ card_pairSetSeq_le_logSizeRadius hJ i ha))
  apply le_trans
  · apply Finset.sum_le_sum
    exact fun i _ ↦ mul_le_mul_left' (pow_le_pow_right₀ (le_of_lt ha) (le_tsub_add (a := 1))) _
  conv_lhs => enter [2]; ext _; rw [pow_add, pow_one, ← mul_assoc, mul_comm]
  rw [← Finset.mul_sum]
  apply mul_le_mul_left'
  apply le_trans (Finset.sum_le_sum (fun i _ ↦ logSizeRadius_le_card_smallBall hJ i ha))
  rw [← Nat.cast_sum]
  gcongr
  rw [← Finset.card_biUnion (fun _ _ _ _ hij ↦ disjoint_smallBall_logSizeBallSeq hJ hij)]
  apply Finset.card_le_card
  rw [Finset.biUnion_subset_iff_forall_subset]
  intro i _
  unfold logSizeBallStruct.smallBall
  apply subset_trans (Finset.filter_subset _ _)
  apply subset_trans <| (antitone_logSizeBallSeq_add_one_subset hJ) (zero_le i)
  simp [finset_logSizeBallSeq_zero]

lemma edist_le_of_mem_pairSet (ha : 1 < a) (hJ_card : #J ≤ a ^ n) {s t : T}
    (h : (s, t) ∈ pairSet J a c) : edist s t ≤ n * c := by
  obtain ⟨i, hiJ, h'⟩ :  ∃ i < #J, (s, t) ∈ pairSetSeq J a c i := by
    simp only [pairSet, Finset.mem_biUnion, Finset.mem_range] at h; exact h
  have hJ : J.Nonempty := Finset.card_pos.mp (Nat.zero_lt_of_lt hiJ)
  wlog hn : 1 ≤ n
  · convert zero_le (n * c)
    convert edist_self _
    simp only [Nat.lt_one_iff.mp (Nat.lt_of_not_ge hn), pow_zero, Nat.cast_le_one] at hJ_card
    have ⟨hs, ht⟩ := Finset.mem_product.mp (pairSet_subset h)
    apply Finset.card_le_one_iff.mp hJ_card ht hs
  simp only [pairSetSeq, hJ, ↓reduceDIte, logSizeBallStruct.ball, Finset.product_eq_sprod,
    Finset.singleton_product, Finset.mem_map, Finset.mem_filter, Function.Embedding.coeFn_mk,
    Prod.mk.injEq, exists_eq_right_right] at h'
  obtain ⟨⟨ht, hdist⟩, rfl⟩ := h'
  refine le_trans hdist (mul_le_mul_right' ?_ c)
  gcongr; exact radius_logSizeBallSeq_le hJ ha hn hJ_card i

open Classical in
lemma iSup_edist_pairSet {E : Type*} [PseudoEMetricSpace E] (ha : 1 < a) (f : T → E) :
    ⨆ (s : J) (t : { t : J // edist s t ≤ c}), edist (f s) (f t)
        ≤ 2 * ⨆ p : pairSet J a c, edist (f p.1.1) (f p.1.2) := by
  rw [iSup_le_iff]; rintro ⟨s, hs⟩
  rw [iSup_le_iff]; rintro ⟨⟨t, ht⟩, hst⟩
  have hJ : J.Nonempty := ⟨s, hs⟩
  let P (l : ℕ) := s ∈ (logSizeBallSeq J hJ a c l).finset ∧ t ∈ (logSizeBallSeq J hJ a c l).finset
  let l := Nat.findGreatest P (#J - 1)
  obtain ⟨hsV, htV⟩ : P l := by
    apply Nat.findGreatest_spec (zero_le _)
    simp only [finset_logSizeBallSeq_zero, P]
    exact ⟨hs, ht⟩
  wlog h : s ∉ (logSizeBallSeq J hJ a c (l + 1)).finset generalizing s t
  · have h' : t ∉ (logSizeBallSeq J hJ a c (l + 1)).finset := by
      have hl : l < #J - 1 := by
        by_contra hl
        simp only [not_lt, tsub_le_iff_right] at hl
        have hlJ : l + 1 = #J := by
          refine Nat.le_antisymm_iff.mpr ⟨?_, hl⟩
          rw [← Nat.sub_add_cancel <| Order.one_le_iff_pos.mpr (Finset.card_pos.mpr hJ)]
          apply add_le_add_right (Nat.findGreatest_le _)
        apply h
        suffices h_emp : (logSizeBallSeq J hJ a c (l + 1)).finset = ∅ from by simp [h_emp]
        rw [← Finset.card_eq_zero, ← Nat.le_zero, ← Nat.sub_self #J, hlJ]
        apply card_finset_logSizeBallSeq_le
      simp only [Decidable.not_not] at h
      have hP := Nat.findGreatest_is_greatest (lt_add_one l) (Nat.add_one_le_of_lt hl)
      simpa [P, h] using hP
    have hts : edist t s ≤ c := by rw [edist_comm]; exact hst
    rw [edist_comm]
    have hP : P = (fun l ↦
      t ∈ (logSizeBallSeq J hJ a c l).finset ∧ s ∈ (logSizeBallSeq J hJ a c l).finset) := by
        ext; simp [P, and_comm]
    simp only [hP, l] at htV hsV h'
    exact this t ht s hs hts htV hsV h'
  simp only [finset_logSizeBallSeq_add_one, logSizeBallStruct.smallBall, Finset.mem_sdiff, hsV,
    Finset.mem_filter, true_and, not_le, not_lt] at h
  have hsB : s ∈ (logSizeBallSeq J hJ a c l).ball c := by
    simp only [logSizeBallStruct.ball, Finset.mem_filter, hsV, true_and]
    apply le_trans h
    simp [mul_le_mul_right']
  have htB : t ∈ (logSizeBallSeq J hJ a c l).ball c := by
    simp only [logSizeBallStruct.ball, Finset.mem_filter, htV, true_and]
    apply le_trans (edist_triangle _ s _)
    apply le_of_le_of_eq (add_le_add h hst)
    nth_rw 3 [← one_mul c]
    rw [← add_mul]
    congr
    rw [ENNReal.sub_add_eq_add_sub _ (ENNReal.one_ne_top),
      ENNReal.add_sub_cancel_right (ENNReal.one_ne_top)]
    rw [← Nat.cast_one]
    gcongr
    exact one_le_radius_logSizeBallSeq hJ ha l
  have hsP : ((logSizeBallSeq J hJ a c l).point, s) ∈ pairSetSeq J a c l := by
    simp [pairSetSeq, hJ, hsB]
  have htP : ((logSizeBallSeq J hJ a c l).point, t) ∈ pairSetSeq J a c l := by
    simp [pairSetSeq, hJ, htB]
  have sup_bound {x y : T} (hxy : (x,y) ∈ pairSetSeq J a c l) :
    edist (f x) (f y) ≤  ⨆ p : pairSet J a c, edist (f p.1.1) (f p.1.2) := by
    simp only [iSup_subtype]
    apply le_iSup_of_le (i := (x,y))
    apply le_iSup_of_le
    apply le_refl
    refine Finset.mem_biUnion.mpr ⟨l, ?_, hxy⟩
    refine Finset.mem_range.mpr <| lt_of_le_of_lt (Nat.findGreatest_le (#J - 1)) ?_
    exact Nat.sub_lt (Finset.card_pos.mpr hJ) zero_lt_one
  rw [two_mul]
  apply le_trans (edist_triangle _ (f (logSizeBallSeq J hJ a c l).point) _)
  rw [edist_comm]
  apply add_le_add (sup_bound hsP) (sup_bound htP)

theorem pair_reduction (J : Finset T) (hJ_card : #J ≤ a ^ n) (ha : 1 < a)
    (E : Type*) [PseudoEMetricSpace E] :
    ∃ K : Finset (T × T), K ⊆ J.product J
      ∧ #K ≤ a * #J
      ∧ (∀ s t, (s, t) ∈ K → edist s t ≤ n * c)
      ∧ (∀ f : T → E,
        ⨆ (s : J) (t : { t : J // edist s t ≤ c}), edist (f s) (f t)
        ≤ 2 * ⨆ p : K, edist (f p.1.1) (f p.1.2)) := by
  refine ⟨pairSet J a c, ?_, ?_, ?_, ?_⟩
  · exact pairSet_subset
  · exact card_pairSet_le ha hJ_card
  · exact fun _ _ ↦ edist_le_of_mem_pairSet ha hJ_card
  · exact iSup_edist_pairSet ha

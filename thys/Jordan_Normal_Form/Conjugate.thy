(*  
    Author:      René Thiemann 
                 Akihisa Yamada
    License:     BSD
*)
theory Conjugate
  imports Complex
begin

class conjugate =
  fixes conjugate :: "'a \<Rightarrow> 'a"
  assumes conjugate_id[simp]: "conjugate (conjugate a) = a"
      and conjugate_cancel_iff[simp]: "conjugate a = conjugate b \<longleftrightarrow> a = b"

class conjugatable_ring = ring + conjugate +
  assumes conjugate_dist_mul: "conjugate (a * b) = conjugate a * conjugate b"
      and conjugate_dist_add: "conjugate (a + b) = conjugate a + conjugate b"
      and conjugate_neg: "conjugate (-a) = - conjugate a"
      and conjugate_zero[simp]: "conjugate 0 = 0"
begin
  lemma conjugate_zero_iff[simp]: "conjugate a = 0 \<longleftrightarrow> a = 0"
    using conjugate_cancel_iff[of _ 0, unfolded conjugate_zero].
end

class conjugatable_field = conjugatable_ring + field

lemma sum_conjugate:
  fixes f :: "'b \<Rightarrow> 'a :: conjugatable_ring"
  assumes finX: "finite X"
  shows "conjugate (sum f X) = sum (\<lambda>x. conjugate (f x)) X"
  using finX by (induct set:finite, auto simp: conjugate_dist_add)

class conjugatable_ordered_ring = conjugatable_ring + ordered_comm_monoid_add +
  assumes conjugate_square_positive: "a * conjugate a \<ge> 0"

class conjugatable_ordered_field = conjugatable_ordered_ring + field
begin
  subclass conjugatable_field..
end

lemma conjugate_square_0:
  fixes a :: "'a :: {conjugatable_ordered_ring, semiring_no_zero_divisors}"
  shows "a * conjugate a = 0 \<Longrightarrow> a = 0" by auto


subsection {* Instantiations *}

instantiation complex :: conjugatable_ordered_ring
begin
  definition [simp]: "conjugate \<equiv> cnj"
  definition [simp]: "x < y \<equiv> Im x = Im y \<and> Re x < Re y"
  definition [simp]: "x \<le> y \<equiv> Im x = Im y \<and> Re x \<le> Re y"
  
  instance by (intro_classes, auto simp: complex.expand)
end

instantiation real :: conjugatable_ordered_ring
begin
  definition [simp]: "conjugate (x::real) \<equiv> x"
  instance by (intro_classes, auto)
end

instantiation rat :: conjugatable_ordered_ring
begin
  definition [simp]: "conjugate (x::rat) \<equiv> x"
  instance by (intro_classes, auto)
end

instantiation int :: conjugatable_ordered_ring
begin
  definition [simp]: "conjugate (x::int) \<equiv> x"
  instance by (intro_classes, auto)
end

end

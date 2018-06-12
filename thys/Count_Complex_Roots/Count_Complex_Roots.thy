(*
    Author:     Wenda Li <wl302@cam.ac.uk / liwenda1990@hotmail.com>
*)

section \<open>Procedures to count the number of complex roots\<close>

theory Count_Complex_Roots imports 
  "Winding_Number_Eval.Winding_Number_Eval" 
  Extended_Sturm
begin

subsection \<open>Misc\<close>
    
(*refined version of the library one with the same name by dropping unnecessary assumptions*) 
corollary path_image_part_circlepath_subset:
  assumes "r\<ge>0"
  shows "path_image(part_circlepath z r st tt) \<subseteq> sphere z r"
proof (cases "st\<le>tt")
  case True
  then show ?thesis 
    by (auto simp: assms path_image_part_circlepath sphere_def dist_norm algebra_simps norm_mult) 
next
  case False
  then have "path_image(part_circlepath z r tt st) \<subseteq> sphere z r"
    by (auto simp: assms path_image_part_circlepath sphere_def dist_norm algebra_simps norm_mult)
  moreover have "path_image(part_circlepath z r tt st) = path_image(part_circlepath z r st tt)"
    using path_image_reversepath by fastforce
  ultimately show ?thesis by auto
qed

(*refined version of the library one with the same name by dropping unnecessary assumptions*)
proposition in_path_image_part_circlepath:
  assumes "w \<in> path_image(part_circlepath z r st tt)" "0 \<le> r"
  shows "norm(w - z) = r"
proof -
  have "w \<in> {c. dist z c = r}"
    by (metis (no_types) path_image_part_circlepath_subset sphere_def subset_eq assms)
  thus ?thesis
    by (simp add: dist_norm norm_minus_commute)
qed  
       
lemma (in ring_1) Ints_minus2: "- a \<in> \<int> \<Longrightarrow> a \<in> \<int>"
  using Ints_minus[of "-a"] by auto

lemma dvd_divide_Ints_iff:
  "b dvd a \<or> b=0 \<longleftrightarrow> of_int a / of_int b \<in> (\<int> :: 'a :: {field,ring_char_0} set)"  
proof
  assume asm:"b dvd a \<or> b=0"
  let ?thesis = "of_int a / of_int b \<in> (\<int> :: 'a :: {field,ring_char_0} set)"
  have ?thesis when "b dvd a"
  proof -
    obtain c where "a=b * c" using \<open>b dvd a\<close> unfolding dvd_def by auto
    then show ?thesis by (auto simp add:field_simps)
  qed
  moreover have ?thesis when "b=0" 
    using that by auto
  ultimately show ?thesis using asm by auto
next
  assume "of_int a / of_int b \<in> (\<int> :: 'a :: {field,ring_char_0} set)"
  from Ints_cases[OF this] obtain c where *:"(of_int::_ \<Rightarrow> 'a) c= of_int a / of_int b"
    by metis 
  have "b dvd a" when "b\<noteq>0"
  proof -
    have "(of_int::_ \<Rightarrow> 'a) a = of_int b * of_int c" using that * by auto
    then have "a = b * c" using of_int_eq_iff by fastforce
    then show ?thesis unfolding dvd_def by auto
  qed
  then show " b dvd a \<or> b = 0" by auto
qed
 
lemma of_int_div_field:
  assumes "d dvd n"
  shows "(of_int::_\<Rightarrow>'a::field_char_0) (n div d) = of_int n / of_int d" 
  apply (subst (2) dvd_mult_div_cancel[OF assms,symmetric])
  by (auto simp add:field_simps)

    
lemma of_real_poly_map_pCons[simp]:"map_poly of_real (pCons a p) = pCons (of_real a) (map_poly of_real p)" 
  by (simp add: map_poly_pCons)    
    
lemma of_real_poly_map_plus[simp]: "map_poly of_real (p + q) = map_poly of_real p +  map_poly of_real q" 
  apply (rule poly_eqI)
  by (auto simp add: coeff_map_poly)  
 
lemma of_real_poly_map_smult[simp]:"map_poly of_real (smult s p) = smult (of_real s) (map_poly of_real p)" 
  apply (rule poly_eqI)
  by (auto simp add: coeff_map_poly)    

lemma of_real_poly_map_mult[simp]:"map_poly of_real (p*q) = map_poly of_real p * map_poly of_real q"
  by (induct p,intro poly_eqI,auto)
    
lemma of_real_poly_map_poly:
  "of_real (poly p x) = poly (map_poly of_real p) (of_real x)" 
by (induct p,auto)    
  
subsection \<open>Combining two real polynomials into a complex one\<close>  

definition cpoly_of:: "real poly \<Rightarrow> real poly \<Rightarrow> complex poly" where
  "cpoly_of pR pI = map_poly of_real pR + smult \<i> (map_poly of_real pI)"
  
lemma cpoly_of_decompose:
    "p = cpoly_of (map_poly Re p) (map_poly Im p)"
  unfolding cpoly_of_def 
  apply (induct p)
  by (auto simp add:map_poly_pCons map_poly_map_poly complex_eq)

lemma cpoly_of_dist_right:
    "cpoly_of (pR*g) (pI*g) = cpoly_of pR pI * (map_poly of_real g)"
  unfolding cpoly_of_def by (simp add: distrib_right)
  
lemma poly_cpoly_of_real:
    "poly (cpoly_of pR pI) (of_real x) = Complex (poly pR x) (poly pI x)"
  unfolding cpoly_of_def by (simp add: Complex_eq of_real_poly_map_poly)
    
lemma poly_cpoly_of_real_iff:
  shows "poly (cpoly_of pR pI) (of_real t) =0 \<longleftrightarrow> poly pR t = 0 \<and> poly pI t=0 "  
  unfolding  poly_cpoly_of_real using Complex_eq_0 by blast    
  
subsection \<open>Checking if there a polynomial root on a closed segment\<close>    
    
definition no_proots_line::"complex poly \<Rightarrow> complex \<Rightarrow> complex \<Rightarrow> bool" where
  "no_proots_line p st tt = (proots_within p (closed_segment st tt) = {})"
   
lemma no_proots_line_code[code]: "no_proots_line p st tt = (if poly p st \<noteq>0 \<and> poly p tt \<noteq> 0 then 
                (let pc = pcompose p [:st, tt - st:];
                     pR = map_poly Re pc;
                     pI = map_poly Im pc;
                     g  = gcd pR pI
                 in if changes_itv_smods 0 1 g (pderiv g) = 0 then True else False) else False)"
            (is "?L = ?R")
proof (cases "poly p st \<noteq>0 \<and> poly p tt \<noteq> 0")
  case False
  thus ?thesis unfolding no_proots_line_def by auto
next
  case True
  then have "poly p st \<noteq> 0" "poly p tt \<noteq> 0" by auto
  define pc pR pI g where 
      "pc = pcompose p [:st, tt-st:]" and
      "pR = map_poly Re pc" and
      "pI = map_poly Im pc" and
      "g  = gcd pR pI"
  have poly_iff:"poly g t=0 \<longleftrightarrow> poly pc t =0" for t
  proof -
    have "poly g t = 0 \<longleftrightarrow> poly pR t =0 \<and> poly pI t =0" 
      unfolding g_def using poly_gcd_iff by auto
    also have "... \<longleftrightarrow> poly pc t =0"
    proof -
      have "cpoly_of pR pI = pc"
        unfolding pc_def pR_def pI_def using cpoly_of_decompose by auto
      then show ?thesis using poly_cpoly_of_real_iff by blast
    qed
    finally show ?thesis by auto
  qed      
  have "?R = (changes_itv_smods 0 1 g (pderiv g) = 0)" 
    using True unfolding pc_def g_def pI_def pR_def
    by (auto simp add:Let_def)      
  also have "... = (card {x. poly g x = 0 \<and> 0 < x \<and> x < 1} = 0)"  
  proof -
    have "poly g 0 \<noteq> 0" 
      using poly_iff[of 0] True unfolding pc_def by (auto simp add:poly_pcompose)
    moreover have "poly g 1 \<noteq> 0" 
      using poly_iff[of 1] True unfolding pc_def by (auto simp add:poly_pcompose)
    ultimately show ?thesis using sturm_interval[of 0 1 g] by auto
  qed
  also have "... = ({x. poly g x = 0 \<and> 0 < x \<and> x < 1} = {})"
  proof -
    have "g\<noteq>0"
    proof (rule ccontr)
      assume "\<not> g \<noteq> 0"
      then have "poly pc 0 =0"
        using poly_iff[of 0] by auto
      then show False using True unfolding pc_def by (auto simp add:poly_pcompose)
    qed
    from poly_roots_finite[OF this] have "finite {x. poly g x = 0 \<and> 0 < x \<and> x < 1}"
      by auto
    then show ?thesis using card_eq_0_iff by auto
  qed
  also have "... = ?L"
  proof -
    have "(\<exists>t. poly g t = 0 \<and> 0 < t \<and> t < 1) \<longleftrightarrow> (\<exists>t::real. poly pc t = 0 \<and> 0 < t \<and> t < 1)"
      using poly_iff by auto
    also have "... \<longleftrightarrow> (\<exists>x. x \<in> closed_segment st tt \<and> poly p x = 0)" 
    proof 
      assume "\<exists>t. poly pc (complex_of_real t) = 0 \<and> 0 < t \<and> t < 1"
      then obtain t where *:"poly pc (of_real t) = 0" and "0 < t" "t < 1" by auto
      define x where "x=poly [:st, tt - st:] t"
      have "x \<in> closed_segment st tt" using \<open>0<t\<close> \<open>t<1\<close> unfolding x_def in_segment
        by (intro exI[where x=t],auto simp add: algebra_simps scaleR_conv_of_real)
      moreover have "poly p x=0" using * unfolding pc_def x_def
        by (auto simp add:poly_pcompose)
      ultimately show "\<exists>x. x \<in> closed_segment st tt \<and> poly p x = 0" by auto
    next
      assume "\<exists>x. x \<in> closed_segment st tt \<and> poly p x = 0"
      then obtain x where "x \<in> closed_segment st tt" "poly p x = 0" by auto
      then obtain t::real where *:"x = (1 - t) *\<^sub>R st + t *\<^sub>R tt" and "0\<le>t" "t\<le>1"  
        unfolding in_segment by auto
      then have "x=poly [:st, tt - st:] t" by (auto simp add: algebra_simps scaleR_conv_of_real)
      then have "poly pc (complex_of_real t) = 0" 
        using \<open>poly p x=0\<close> unfolding pc_def by (auto simp add:poly_pcompose)
      moreover have "t\<noteq>0" "t\<noteq>1" using True *  \<open>poly p x=0\<close> by auto
      then have "0<t" "t<1" using \<open>0\<le>t\<close> \<open>t\<le>1\<close> by auto
      ultimately show "\<exists>t. poly pc (complex_of_real t) = 0 \<and> 0 < t \<and> t < 1" by auto
    qed        
    finally show ?thesis
      unfolding no_proots_line_def proots_within_def 
      by blast
  qed
  finally show ?thesis by simp
qed
   
  
subsection \<open>Counting roots in a retangle\<close>  
  
definition proots_rectangle ::"complex poly \<Rightarrow> complex \<Rightarrow> complex \<Rightarrow> int" where
  "proots_rectangle p lb ub = proots_count p (box lb ub)"  
  
  
lemma closed_segment_imp_Re_Im:
  fixes x::complex
  assumes "x\<in>closed_segment lb ub" 
  shows "Re lb \<le> Re ub \<Longrightarrow> Re lb \<le> Re x \<and> Re x \<le> Re ub" 
        "Im lb \<le> Im ub \<Longrightarrow> Im lb \<le> Im x \<and> Im x \<le> Im ub"
proof -
  obtain u where x_u:"x=(1 - u) *\<^sub>R lb + u *\<^sub>R ub " and "0 \<le> u" "u \<le> 1"
    using assms unfolding closed_segment_def by auto
  have "Re lb \<le> Re x" when "Re lb \<le> Re ub"
  proof -
    have "Re x = Re ((1 - u) *\<^sub>R lb + u *\<^sub>R ub)"
      using x_u by blast
    also have "... = Re (lb + u *\<^sub>R (ub - lb))" by (auto simp add:algebra_simps)
    also have "... = Re lb + u * (Re ub - Re lb)" by auto
    also have "... \<ge> Re lb" using \<open>u\<ge>0\<close> \<open>Re lb \<le> Re ub\<close> by auto
    finally show ?thesis .
  qed
  moreover have "Im lb \<le> Im x" when "Im lb \<le> Im ub"
  proof -
    have "Im x = Im ((1 - u) *\<^sub>R lb + u *\<^sub>R ub)"
      using x_u by blast
    also have "... = Im (lb + u *\<^sub>R (ub - lb))" by (auto simp add:algebra_simps)
    also have "... = Im lb + u * (Im ub - Im lb)" by auto
    also have "... \<ge> Im lb" using \<open>u\<ge>0\<close> \<open>Im lb \<le> Im ub\<close> by auto
    finally show ?thesis .
  qed
  moreover have "Re x \<le> Re ub" when "Re lb \<le> Re ub"
  proof -
    have "Re x = Re ((1 - u) *\<^sub>R lb + u *\<^sub>R ub)"
      using x_u by blast
    also have "... = (1 - u) * Re lb + u * Re ub" by auto
    also have "... \<le> (1 - u) * Re ub + u * Re ub"
      using \<open>u\<le>1\<close> \<open>Re lb \<le> Re ub\<close> by (auto simp add: mult_left_mono)
    also have "... = Re ub" by (auto simp add:algebra_simps)
    finally show ?thesis .
  qed
  moreover have "Im x \<le> Im ub" when "Im lb \<le> Im ub"
  proof -
    have "Im x = Im ((1 - u) *\<^sub>R lb + u *\<^sub>R ub)"
      using x_u by blast
    also have "... = (1 - u) * Im lb + u * Im ub" by auto
    also have "... \<le> (1 - u) * Im ub + u * Im ub"
      using \<open>u\<le>1\<close> \<open>Im lb \<le> Im ub\<close> by (auto simp add: mult_left_mono)
    also have "... = Im ub" by (auto simp add:algebra_simps)
    finally show ?thesis .
  qed
  ultimately show 
      "Re lb \<le> Re ub \<Longrightarrow> Re lb \<le> Re x \<and> Re x \<le> Re ub" 
      "Im lb \<le> Im ub \<Longrightarrow> Im lb \<le> Im x \<and> Im x \<le> Im ub" 
    by auto
qed
  
lemma closed_segment_degen_complex:
  "\<lbrakk>Re lb = Re ub; Im lb \<le> Im ub \<rbrakk> 
    \<Longrightarrow> x \<in> closed_segment lb ub \<longleftrightarrow> Re x = Re lb \<and> Im lb \<le> Im x \<and> Im x \<le> Im ub "
  "\<lbrakk>Im lb = Im ub; Re lb \<le> Re ub \<rbrakk> 
    \<Longrightarrow> x \<in> closed_segment lb ub \<longleftrightarrow> Im x = Im lb \<and> Re lb \<le> Re x \<and> Re x \<le> Re ub "  
proof -
  show "x \<in> closed_segment lb ub \<longleftrightarrow> Re x = Re lb \<and> Im lb \<le> Im x \<and> Im x \<le> Im ub"
    when "Re lb = Re ub" "Im lb \<le> Im ub"
  proof 
    show "Re x = Re lb \<and> Im lb \<le> Im x \<and> Im x \<le> Im ub" when "x \<in> closed_segment lb ub"
      using closed_segment_imp_Re_Im[OF that] \<open>Re lb = Re ub\<close> \<open>Im lb \<le> Im ub\<close> by fastforce
  next
    assume asm:"Re x = Re lb \<and> Im lb \<le> Im x \<and> Im x \<le> Im ub"
    define u where "u=(Im x - Im lb)/ (Im ub - Im lb)"
    have "x = (1 - u) *\<^sub>R lb + u *\<^sub>R ub"
      unfolding u_def using asm \<open>Re lb = Re ub\<close> \<open>Im lb \<le> Im ub\<close>
      apply (intro complex_eqI)
      apply (auto simp add:field_simps)
      apply (cases "Im ub - Im lb =0")
      apply (auto simp add:field_simps)
      done
    moreover have "0\<le>u" "u\<le>1" unfolding u_def 
      using \<open>Im lb \<le> Im ub\<close> asm
      by (cases "Im ub - Im lb =0",auto simp add:field_simps)+
    ultimately show "x \<in> closed_segment lb ub" unfolding closed_segment_def by auto
  qed
  show "x \<in> closed_segment lb ub \<longleftrightarrow> Im x = Im lb \<and> Re lb \<le> Re x \<and> Re x \<le> Re ub"
    when "Im lb = Im ub" "Re lb \<le> Re ub"
  proof 
    show "Im x = Im lb \<and> Re lb \<le> Re x \<and> Re x \<le> Re ub" when "x \<in> closed_segment lb ub"
      using closed_segment_imp_Re_Im[OF that] \<open>Im lb = Im ub\<close> \<open>Re lb \<le> Re ub\<close> by fastforce
  next
    assume asm:"Im x = Im lb \<and> Re lb \<le> Re x \<and> Re x \<le> Re ub"
    define u where "u=(Re x - Re lb)/ (Re ub - Re lb)"
    have "x = (1 - u) *\<^sub>R lb + u *\<^sub>R ub"
      unfolding u_def using asm \<open>Im lb = Im ub\<close> \<open>Re lb \<le> Re ub\<close>
      apply (intro complex_eqI)
       apply (auto simp add:field_simps)
      apply (cases "Re ub - Re lb =0")
       apply (auto simp add:field_simps)
      done
    moreover have "0\<le>u" "u\<le>1" unfolding u_def 
      using \<open>Re lb \<le> Re ub\<close> asm
      by (cases "Re ub - Re lb =0",auto simp add:field_simps)+
    ultimately show "x \<in> closed_segment lb ub" unfolding closed_segment_def by auto
  qed   
qed  
   
lemma complex_box_ne_empty: 
  fixes a b::complex
  shows 
    "cbox a b \<noteq> {} \<longleftrightarrow> (Re a \<le> Re b \<and> Im a \<le> Im b)"
    "box a b \<noteq> {} \<longleftrightarrow> (Re a < Re b \<and> Im a < Im b)"
  by (auto simp add:box_ne_empty Basis_complex_def)  
      
lemma proots_rectangle_code1:
  "proots_rectangle p lb ub = (if Re lb < Re ub \<and> Im lb < Im ub then 
            if p\<noteq>0 then 
            if no_proots_line p lb (Complex (Re ub) (Im lb))
            \<and> no_proots_line p (Complex (Re ub) (Im lb)) ub
            \<and> no_proots_line p ub (Complex (Re lb) (Im ub))
            \<and> no_proots_line p (Complex (Re lb) (Im ub)) lb then  
            (
            let p1 = pcompose p [:lb,  Complex (Re ub - Re lb) 0:];
                pR1 = map_poly Re p1; pI1 = map_poly Im p1; gc1 = gcd pR1 pI1;
                p2 = pcompose p [:Complex (Re ub) (Im lb), Complex 0 (Im ub - Im lb):];
                pR2 = map_poly Re p2; pI2 = map_poly Im p2; gc2 = gcd pR2 pI2;
                p3 = pcompose p [:ub, Complex (Re lb - Re ub) 0:];
                pR3 = map_poly Re p3; pI3 = map_poly Im p3; gc3 = gcd pR3 pI3;
                p4 = pcompose p [:Complex (Re lb) (Im ub), Complex 0 (Im lb - Im ub):];
                pR4 = map_poly Re p4; pI4 = map_poly Im p4; gc4 = gcd pR4 pI4
            in 
              - (changes_alt_itv_smods 0 1 (pR1 div gc1) (pI1 div gc1)
                + changes_alt_itv_smods 0 1 (pR2 div gc2) (pI2 div gc2)
                + changes_alt_itv_smods 0 1 (pR3 div gc3) (pI3 div gc3)
                + changes_alt_itv_smods 0 1 (pR4 div gc4) (pI4 div gc4))  div 4
            )
            else Code.abort (STR ''proots_rectangle fails when there is a root on the border.'') 
            (\<lambda>_. proots_rectangle p lb ub)
            else Code.abort (STR ''proots_rectangle fails when p=0.'') 
            (\<lambda>_. proots_rectangle p lb ub)
            else 0)"
proof -
  have ?thesis when "\<not> (Re lb < Re ub \<and> Im lb < Im ub)" 
  proof -
    have "box lb ub = {}" using complex_box_ne_empty[of lb ub] that by auto
    then have "proots_rectangle p lb ub = 0" unfolding proots_rectangle_def by auto
    then show ?thesis by (simp add:that) 
  qed
  moreover have ?thesis when "Re lb < Re ub \<and> Im lb < Im ub" "p=0"
    using that by simp
  moreover have ?thesis when     
            "Re lb < Re ub" "Im lb < Im ub" "p\<noteq>0" 
            and no_proots:
            "no_proots_line p lb (Complex (Re ub) (Im lb))"
            "no_proots_line p (Complex (Re ub) (Im lb)) ub"
            "no_proots_line p ub (Complex (Re lb) (Im ub))"
            "no_proots_line p (Complex (Re lb) (Im ub)) lb"
  proof -
    define l1 where "l1 = linepath lb (Complex (Re ub) (Im lb))"
    define l2 where "l2 = linepath (Complex (Re ub) (Im lb)) ub"
    define l3 where "l3 = linepath ub (Complex (Re lb) (Im ub))"
    define l4 where "l4 = linepath (Complex (Re lb) (Im ub)) lb"
    define rec where "rec = l1 +++ l2 +++ l3 +++ l4"
    have valid[simp]:"valid_path rec" and loop[simp]:"pathfinish rec = pathstart rec"
      unfolding rec_def l1_def l2_def l3_def l4_def by auto
    have path_no_proots:"path_image rec \<inter> proots p = {}" 
      unfolding rec_def l1_def l2_def l3_def l4_def
      apply (subst path_image_join,simp_all del:Complex_eq)+  
      using no_proots[unfolded no_proots_line_def] by (auto simp del:Complex_eq)
    
    define g1 where "g1 = poly p o l1" 
    define g2 where "g2 = poly p o l2" 
    define g3 where "g3 = poly p o l3" 
    define g4 where "g4 = poly p o l4"    
    have [simp]: "path g1" "path g2" "path g3" "path g4"
      "pathfinish g1 = pathstart g2" "pathfinish g2 = pathstart g3" "pathfinish g3 = pathstart g4"
      "pathfinish g4 = pathstart g1"
      unfolding g1_def g2_def g3_def g4_def l1_def l2_def l3_def l4_def
      by (auto intro!: path_continuous_image continuous_intros 
          simp add:pathfinish_compose pathstart_compose)
    have [simp]: "finite_ReZ_segments g1 0" "finite_ReZ_segments g2 0" 
         "finite_ReZ_segments g3 0" "finite_ReZ_segments g4 0"
      unfolding g1_def l1_def g2_def l2_def g3_def l3_def g4_def l4_def poly_linepath_comp 
      by (rule finite_ReZ_segments_poly_of_real)+
    define p1 pR1 pI1 gc1
           p2 pR2 pI2 gc2
           p3 pR3 pI3 gc3
           p4 pR4 pI4 gc4
      where "p1 = pcompose p [:lb,  Complex (Re ub - Re lb) 0:]"
             and "pR1 = map_poly Re p1" and "pI1 = map_poly Im p1" and "gc1 = gcd pR1 pI1"
             and "p2 = pcompose p [:Complex (Re ub) (Im lb), Complex 0 (Im ub - Im lb):]"
             and "pR2 = map_poly Re p2" and "pI2 = map_poly Im p2" and "gc2 = gcd pR2 pI2"
             and "p3 = pcompose p [:ub, Complex (Re lb - Re ub) 0:]"
             and "pR3 = map_poly Re p3" and "pI3 = map_poly Im p3" and "gc3 = gcd pR3 pI3"
             and "p4 = pcompose p [:Complex (Re lb) (Im ub), Complex 0 (Im lb - Im ub):]"
             and "pR4 = map_poly Re p4" and "pI4 = map_poly Im p4" and "gc4 = gcd pR4 pI4"
    have "gc1\<noteq>0" "gc2\<noteq>0" "gc3\<noteq>0" "gc4\<noteq>0"
    proof -
      show "gc1\<noteq>0" 
      proof (rule ccontr)
        assume "\<not> gc1 \<noteq> 0"
        then have "pI1 = 0" "pR1 = 0" unfolding gc1_def by auto
        then have "p1 = 0" unfolding pI1_def pR1_def 
          by (metis cpoly_of_decompose map_poly_0)
        then have "p=0" unfolding p1_def using \<open>Re lb < Re ub\<close>
          by (auto elim!:pcompose_eq_0 simp add:Complex_eq_0)
        then show False using \<open>p\<noteq>0\<close> by simp
      qed
      show "gc2\<noteq>0" 
      proof (rule ccontr)
        assume "\<not> gc2 \<noteq> 0"
        then have "pI2 = 0" "pR2 = 0" unfolding gc2_def by auto
        then have "p2 = 0" unfolding pI2_def pR2_def 
          by (metis cpoly_of_decompose map_poly_0)
        then have "p=0" unfolding p2_def using \<open>Im lb < Im ub\<close>
          by (auto elim!:pcompose_eq_0 simp add:Complex_eq_0)
        then show False using \<open>p\<noteq>0\<close> by simp
      qed 
      show "gc3\<noteq>0" 
      proof (rule ccontr)
        assume "\<not> gc3 \<noteq> 0"
        then have "pI3 = 0" "pR3 = 0" unfolding gc3_def by auto
        then have "p3 = 0" unfolding pI3_def pR3_def 
          by (metis cpoly_of_decompose map_poly_0)
        then have "p=0" unfolding p3_def using \<open>Re lb < Re ub\<close>
          by (auto elim!:pcompose_eq_0 simp add:Complex_eq_0)
        then show False using \<open>p\<noteq>0\<close> by simp
      qed
      show "gc4\<noteq>0" 
      proof (rule ccontr)
        assume "\<not> gc4 \<noteq> 0"
        then have "pI4 = 0" "pR4 = 0" unfolding gc4_def by auto
        then have "p4 = 0" unfolding pI4_def pR4_def 
          by (metis cpoly_of_decompose map_poly_0)
        then have "p=0" unfolding p4_def using \<open>Im lb < Im ub\<close>
          by (auto elim!:pcompose_eq_0 simp add:Complex_eq_0)
        then show False using \<open>p\<noteq>0\<close> by simp
      qed 
    qed
    define sms where 
      "sms = (changes_alt_itv_smods 0 1 (pR1 div gc1) (pI1 div gc1)
                + changes_alt_itv_smods 0 1 (pR2 div gc2) (pI2 div gc2)
                + changes_alt_itv_smods 0 1 (pR3 div gc3) (pI3 div gc3)
                + changes_alt_itv_smods 0 1 (pR4 div gc4) (pI4 div gc4))"
    have "proots_rectangle p lb ub = (\<Sum>r\<in>proots p. winding_number rec r * (order r p))" 
    proof -
      have "winding_number rec x * of_nat (order x p) = 0" 
        when "x\<in>proots p - proots_within p (box lb ub)" for x 
      proof -
        have *:"cbox lb ub = box lb ub \<union> path_image rec"
        proof -
          have "x\<in>cbox lb ub" when "x\<in>box lb ub \<union> path_image rec" for x
            using that \<open>Re lb<Re ub\<close> \<open>Im lb<Im ub\<close>
            unfolding box_def cbox_def Basis_complex_def rec_def l1_def l2_def l3_def l4_def
            apply (auto simp add:path_image_join closed_segment_degen_complex)          
                   apply (subst (asm) closed_segment_commute,simp add: closed_segment_degen_complex)+
            done  
          moreover have "x\<in>box lb ub \<union> path_image rec" when "x\<in>cbox lb ub" for x
            using that
            unfolding box_def cbox_def Basis_complex_def rec_def l1_def l2_def l3_def l4_def
            apply (auto simp add:path_image_join closed_segment_degen_complex)
             apply (subst (asm) (1 2) closed_segment_commute,simp add:closed_segment_degen_complex)+
            done
          ultimately show ?thesis by auto
        qed
        moreover have "x\<notin>path_image rec" 
          using path_no_proots that by auto
        ultimately have "x\<notin>cbox lb ub" using that by simp
        from winding_number_zero_outside[OF valid_path_imp_path[OF valid] _ loop this,simplified] * 
        have "winding_number rec x = 0" by auto
        then show ?thesis by auto
      qed
      moreover have "of_nat (order x p) = winding_number rec x * of_nat (order x p)" when 
        "x \<in> proots_within p (box lb ub)" for x 
      proof -
        have "x\<in>box lb ub" using that unfolding proots_within_def by auto 
        then have order_asms:"Re lb < Re x" "Re x < Re ub" "Im lb < Im x" "Im x < Im ub"  
          by (auto simp add:box_def Basis_complex_def)  
        have "winding_number rec x = 1"
          unfolding rec_def l1_def l2_def l3_def l4_def 
        proof eval_winding 
          let ?l1 = "linepath lb (Complex (Re ub) (Im lb))"
          and ?l2 = "linepath (Complex (Re ub) (Im lb)) ub"
          and ?l3 = "linepath ub (Complex (Re lb) (Im ub))"
          and ?l4 = "linepath (Complex (Re lb) (Im ub)) lb"
          show l1: "x \<notin> path_image ?l1" and l2: "x \<notin> path_image ?l2" and 
               l3: "x \<notin> path_image ?l3" and l4:"x \<notin> path_image ?l4"
            using no_proots that unfolding no_proots_line_def by auto
          show "- of_real (cindex_pathE ?l1 x + (cindex_pathE ?l2 x +
            (cindex_pathE ?l3 x + cindex_pathE ?l4 x))) = 2 * 1"
          proof -
            have "(Im x - Im ub) * (Re ub - Re lb) < 0" 
              using mult_less_0_iff order_asms(1) order_asms(2) order_asms(4) by fastforce
            then have "cindex_pathE ?l3 x = -1" 
              apply (subst cindex_pathE_linepath)
              using l3 by (auto simp add:algebra_simps order_asms)
            moreover have "(Im lb - Im x) * (Re ub - Re lb) <0" 
              using mult_less_0_iff order_asms(1) order_asms(2) order_asms(3) by fastforce
            then have "cindex_pathE ?l1 x = -1"    
              apply (subst cindex_pathE_linepath)
              using l1 by (auto simp add:algebra_simps order_asms)  
            moreover have "cindex_pathE ?l2 x = 0"    
              apply (subst cindex_pathE_linepath)
              using l2 order_asms by auto
            moreover have "cindex_pathE ?l4 x = 0"
              apply (subst cindex_pathE_linepath)
              using l4 order_asms by auto
            ultimately show ?thesis by auto
          qed
        qed
        then show ?thesis by auto
      qed 
      ultimately show ?thesis using \<open>p\<noteq>0\<close>
      unfolding proots_rectangle_def proots_count_def 
        by (auto intro!: sum.mono_neutral_cong_left[of "proots p" "proots_within p (box lb ub)"])
    qed    
    also have "... = 1/(2 * of_real pi * \<i>) *contour_integral rec (\<lambda>x. deriv (poly p) x / poly p x)"
    proof -
      have "contour_integral rec (\<lambda>x. deriv (poly p) x / poly p x) = 2 * of_real pi * \<i> 
              * (\<Sum>x | poly p x = 0. winding_number rec x * of_int (zorder (poly p) x))"
      proof (rule argument_principle[of UNIV "poly p" "{}" "\<lambda>_. 1" rec,simplified])
        show "connected (UNIV::complex set)" using connected_UNIV[where 'a=complex] .
        show "path_image rec \<subseteq> UNIV - {x. poly p x = 0}" 
          using path_no_proots unfolding proots_within_def by auto
        show "finite {x. poly p x = 0}" by (simp add: poly_roots_finite that(3))
      qed
      also have " ... = 2 * of_real pi * \<i> * (\<Sum>x\<in>proots p. winding_number rec x * (order x p))" 
        unfolding proots_within_def 
        apply (auto intro!:sum.cong simp add:order_zorder[OF _ \<open>p\<noteq>0\<close>] )
        by (metis nat_eq_iff2 of_nat_nat order_root order_zorder that(3))
      finally show ?thesis by auto
    qed  
    also have "... = winding_number (poly p \<circ> rec) 0"
    proof -
      have "0 \<notin> path_image (poly p \<circ> rec)" 
        using path_no_proots unfolding path_image_compose proots_within_def by fastforce
      from winding_number_comp[OF _ poly_holomorphic_on _ _ this,of UNIV,simplified]
      show ?thesis by auto
    qed
    also have winding_eq:"... = - cindex_pathE (poly p \<circ> rec) 0 / 2"
    proof (rule winding_number_cindex_pathE)
      show "finite_ReZ_segments (poly p \<circ> rec) 0"
        unfolding rec_def path_compose_join 
        apply (fold g1_def g2_def g3_def g4_def)
        by (auto intro!: finite_ReZ_segments_joinpaths path_join_imp)
      show "valid_path (poly p \<circ> rec)"
        by (rule valid_path_compose_holomorphic[where S=UNIV]) auto
      show "0 \<notin> path_image (poly p \<circ> rec)"
        using path_no_proots unfolding path_image_compose proots_def by fastforce
      show "pathfinish (poly p \<circ> rec) = pathstart (poly p \<circ> rec)"
        unfolding rec_def pathstart_compose pathfinish_compose  by (auto simp add:l1_def l4_def)   
    qed
    also have cindex_pathE_eq:"... = of_int (- sms) / of_int 4"
    proof -
      have "cindex_pathE (poly p \<circ> rec) 0 = cindex_pathE (g1+++g2+++g3+++g4) 0"
        unfolding rec_def path_compose_join g1_def g2_def g3_def g4_def by simp
      also have "... = cindex_pathE g1 0 + cindex_pathE g2 0 + cindex_pathE g3 0 + cindex_pathE g4 0"
        by (subst cindex_pathE_joinpaths,auto intro!:finite_ReZ_segments_joinpaths)+
      also have "... = cindex_polyE 0 1 (pI1 div gc1) (pR1 div gc1)
                     + cindex_polyE 0 1 (pI2 div gc2) (pR2 div gc2)
                     + cindex_polyE 0 1 (pI3 div gc3) (pR3 div gc3)
                     + cindex_polyE 0 1 (pI4 div gc4) (pR4 div gc4)"
      proof - 
        have "cindex_pathE g1 0 = cindex_polyE 0 1 (pI1 div gc1) (pR1 div gc1)"
        proof -
          have *:"g1 = poly p1 o of_real"
            unfolding g1_def p1_def l1_def poly_linepath_comp
            by (subst (5) complex_surj[symmetric],simp)
          then have "cindex_pathE g1 0  = cindexE 0 1 (\<lambda>t. poly pI1 t / poly pR1 t)"
            unfolding cindex_pathE_def pR1_def pI1_def 
            by (simp add:Im_poly_of_real Re_poly_of_real)
          also have "... = cindex_polyE 0 1 pI1 pR1"
            using cindexE_eq_cindex_polyE by auto
          also have "... = cindex_polyE 0 1 (pI1 div gc1) (pR1 div gc1)"
            using \<open>gc1\<noteq>0\<close>
            apply (subst (2) cindex_polyE_mult_cancel[of gc1,symmetric])
            by (simp_all add: gc1_def)  
          finally show ?thesis .
        qed
        moreover have "cindex_pathE g2 0 = cindex_polyE 0 1 (pI2 div gc2) (pR2 div gc2)"
        proof -
          have "g2 = poly p2 o of_real"
            unfolding g2_def p2_def l2_def poly_linepath_comp
            by (subst (5) complex_surj[symmetric],simp)
          then have "cindex_pathE g2 0  = cindexE 0 1 (\<lambda>t. poly pI2 t / poly pR2 t)"
            unfolding cindex_pathE_def pR2_def pI2_def 
            by (simp add:Im_poly_of_real Re_poly_of_real)
          also have "... = cindex_polyE 0 1 pI2 pR2"
            using cindexE_eq_cindex_polyE by auto
          also have "... = cindex_polyE 0 1 (pI2 div gc2) (pR2 div gc2)"
            using \<open>gc2\<noteq>0\<close>
            apply (subst (2) cindex_polyE_mult_cancel[of gc2,symmetric])
              by (simp_all add: gc2_def)
          finally show ?thesis .
        qed  
        moreover have "cindex_pathE g3 0 = cindex_polyE 0 1 (pI3 div gc3) (pR3 div gc3)"
        proof -
          have "g3 = poly p3 o of_real"
            unfolding g3_def p3_def l3_def poly_linepath_comp
            by (subst (5) complex_surj[symmetric],simp)
          then have "cindex_pathE g3 0  = cindexE 0 1 (\<lambda>t. poly pI3 t / poly pR3 t)"
            unfolding cindex_pathE_def pR3_def pI3_def 
            by (simp add:Im_poly_of_real Re_poly_of_real)
          also have "... = cindex_polyE 0 1 pI3 pR3"
            using cindexE_eq_cindex_polyE by auto
          also have "... = cindex_polyE 0 1 (pI3 div gc3) (pR3 div gc3)"
            using \<open>gc3\<noteq>0\<close>
            apply (subst (2) cindex_polyE_mult_cancel[of gc3,symmetric])
            by (simp_all add: gc3_def)
          finally show ?thesis .
        qed     
        moreover have "cindex_pathE g4 0 = cindex_polyE 0 1 (pI4 div gc4) (pR4 div gc4)"
        proof -
          have "g4 = poly p4 o of_real"
            unfolding g4_def p4_def l4_def poly_linepath_comp
            by (subst (5) complex_surj[symmetric],simp)
          then have "cindex_pathE g4 0  = cindexE 0 1 (\<lambda>t. poly pI4 t / poly pR4 t)"
            unfolding cindex_pathE_def pR4_def pI4_def 
            by (simp add:Im_poly_of_real Re_poly_of_real)
          also have "... = cindex_polyE 0 1 pI4 pR4"
            using cindexE_eq_cindex_polyE by auto
          also have "... = cindex_polyE 0 1 (pI4 div gc4) (pR4 div gc4)"
            using \<open>gc4\<noteq>0\<close>
            apply (subst (2) cindex_polyE_mult_cancel[of gc4,symmetric])
            by (simp_all add: gc4_def)
          finally show ?thesis .
        qed      
        ultimately show ?thesis by auto
      qed
      also have "... = sms / 2" 
      proof -
        have "cindex_polyE 0 1 (pI1 div gc1) (pR1 div gc1) 
            = changes_alt_itv_smods 0 1 (pR1 div gc1) (pI1 div gc1) / 2"
          apply (rule cindex_polyE_changes_alt_itv_mods)
          using \<open>gc1\<noteq>0\<close> unfolding gc1_def by (auto intro:div_gcd_coprime) 
        moreover have "cindex_polyE 0 1 (pI2 div gc2) (pR2 div gc2) 
            = changes_alt_itv_smods 0 1 (pR2 div gc2) (pI2 div gc2) / 2"
          apply (rule cindex_polyE_changes_alt_itv_mods)
          using \<open>gc2\<noteq>0\<close> unfolding gc2_def by (auto intro:div_gcd_coprime)    
        moreover have "cindex_polyE 0 1 (pI3 div gc3) (pR3 div gc3) 
            = changes_alt_itv_smods 0 1 (pR3 div gc3) (pI3 div gc3) / 2"
          apply (rule cindex_polyE_changes_alt_itv_mods)
          using \<open>gc3\<noteq>0\<close> unfolding gc3_def by (auto intro:div_gcd_coprime)    
        moreover have "cindex_polyE 0 1 (pI4 div gc4) (pR4 div gc4) 
            = changes_alt_itv_smods 0 1 (pR4 div gc4) (pI4 div gc4) / 2"
          apply (rule cindex_polyE_changes_alt_itv_mods)
          using \<open>gc4\<noteq>0\<close> unfolding gc4_def by (auto intro:div_gcd_coprime)
        ultimately show ?thesis unfolding sms_def by auto
      qed
      finally have *:"cindex_pathE (poly p \<circ> rec) 0 = real_of_int sms / 2" .
      show ?thesis 
        apply (subst *)
        by auto
    qed  
    finally have "(of_int::_\<Rightarrow> complex) (proots_rectangle p lb ub) = of_int (- sms) / of_int 4" .
    moreover have "4 dvd sms" 
    proof -
      have "winding_number (poly p \<circ> rec) 0 \<in> \<int>"
      proof (rule integer_winding_number)
        show "path (poly p \<circ> rec)"
          by (auto intro!:valid_path_compose_holomorphic[where S=UNIV] valid_path_imp_path)
        show "pathfinish (poly p \<circ> rec) = pathstart (poly p \<circ> rec)"
          unfolding rec_def path_compose_join
          by (auto simp add:l1_def l4_def pathfinish_compose pathstart_compose)
        show "0 \<notin> path_image (poly p \<circ> rec)"
          using path_no_proots unfolding path_image_compose proots_def by fastforce
      qed         
      then have "of_int (- sms) / of_int 4 \<in> (\<int>::complex set)"
        by (simp only: winding_eq cindex_pathE_eq)
      then show ?thesis by (subst (asm) dvd_divide_Ints_iff[symmetric],auto) 
    qed
    ultimately have "proots_rectangle p lb ub = - sms div 4"
      apply (subst (asm) of_int_div_field[symmetric])
      by auto
    then show ?thesis 
      unfolding Let_def
      apply (fold p1_def p2_def p3_def p4_def pI1_def pR1_def pI2_def pR2_def pI3_def pR3_def
          pI4_def pR4_def gc1_def gc2_def gc3_def gc4_def)
      apply (fold sms_def)
      using that by auto
  qed
  ultimately show ?thesis by fastforce
qed
  
(*further refinement*)
lemma proots_rectangle_code2[code]:
  "proots_rectangle p lb ub = (if Re lb < Re ub \<and> Im lb < Im ub then 
            if p\<noteq>0 then 
            if poly p lb \<noteq> 0 \<and> poly p (Complex (Re ub) (Im lb)) \<noteq>0 
               \<and> poly p ub \<noteq>0 \<and> poly p (Complex (Re lb) (Im ub)) \<noteq>0 
            then
              (let p1 = pcompose p [:lb,  Complex (Re ub - Re lb) 0:];
                pR1 = map_poly Re p1; pI1 = map_poly Im p1; gc1 = gcd pR1 pI1;
                p2 = pcompose p [:Complex (Re ub) (Im lb), Complex 0 (Im ub - Im lb):];
                pR2 = map_poly Re p2; pI2 = map_poly Im p2; gc2 = gcd pR2 pI2;
                p3 = pcompose p [:ub, Complex (Re lb - Re ub) 0:];
                pR3 = map_poly Re p3; pI3 = map_poly Im p3; gc3 = gcd pR3 pI3;
                p4 = pcompose p [:Complex (Re lb) (Im ub), Complex 0 (Im lb - Im ub):];
                pR4 = map_poly Re p4; pI4 = map_poly Im p4; gc4 = gcd pR4 pI4
              in
                if changes_itv_smods 0 1 gc1 (pderiv gc1) = 0
                   \<and> changes_itv_smods 0 1 gc2 (pderiv gc2) = 0 
                   \<and> changes_itv_smods 0 1 gc3 (pderiv gc3) = 0
                   \<and> changes_itv_smods 0 1 gc4 (pderiv gc4) = 0
                then 
                   - (changes_alt_itv_smods 0 1 (pR1 div gc1) (pI1 div gc1)
                    + changes_alt_itv_smods 0 1 (pR2 div gc2) (pI2 div gc2)
                    + changes_alt_itv_smods 0 1 (pR3 div gc3) (pI3 div gc3)
                    + changes_alt_itv_smods 0 1 (pR4 div gc4) (pI4 div gc4))  div 4
                else Code.abort (STR ''proots_rectangle fails when there is a root on the border.'') 
                        (\<lambda>_. proots_rectangle p lb ub))
            else Code.abort (STR ''proots_rectangle fails when there is a root on the border.'') 
              (\<lambda>_. proots_rectangle p lb ub)  
            else Code.abort (STR ''proots_rectangle fails when p=0.'') 
            (\<lambda>_. proots_rectangle p lb ub)
            else 0)"
proof -
  define p1 pR1 pI1 gc1
           p2 pR2 pI2 gc2
           p3 pR3 pI3 gc3
           p4 pR4 pI4 gc4
      where "p1 = pcompose p [:lb,  Complex (Re ub - Re lb) 0:]"
             and "pR1 = map_poly Re p1" and "pI1 = map_poly Im p1" and "gc1 = gcd pR1 pI1"
             and "p2 = pcompose p [:Complex (Re ub) (Im lb), Complex 0 (Im ub - Im lb):]"
             and "pR2 = map_poly Re p2" and "pI2 = map_poly Im p2" and "gc2 = gcd pR2 pI2"
             and "p3 = pcompose p [:ub, Complex (Re lb - Re ub) 0:]"
             and "pR3 = map_poly Re p3" and "pI3 = map_poly Im p3" and "gc3 = gcd pR3 pI3"
             and "p4 = pcompose p [:Complex (Re lb) (Im ub), Complex 0 (Im lb - Im ub):]"
             and "pR4 = map_poly Re p4" and "pI4 = map_poly Im p4" and "gc4 = gcd pR4 pI4" 
  define sms where 
      "sms = (- (changes_alt_itv_smods 0 1 (pR1 div gc1) (pI1 div gc1) +
                       changes_alt_itv_smods 0 1 (pR2 div gc2) (pI2 div gc2) +
                       changes_alt_itv_smods 0 1 (pR3 div gc3) (pI3 div gc3) +
                       changes_alt_itv_smods 0 1 (pR4 div gc4) (pI4 div gc4)) div
                    4)"
  have more_folds:"p1 = p \<circ>\<^sub>p [:lb, Complex (Re ub) (Im lb) - lb:]"
    "p2 = p \<circ>\<^sub>p [:Complex (Re ub) (Im lb), ub - Complex (Re ub) (Im lb):]"
    "p3 = p \<circ>\<^sub>p [:ub, Complex (Re lb) (Im ub) - ub:]"
    "p4 = p \<circ>\<^sub>p [:Complex (Re lb) (Im ub), lb - Complex (Re lb) (Im ub):]"
    subgoal unfolding p1_def 
      by (subst (10) complex_surj[symmetric],auto simp add:minus_complex.code)
    subgoal unfolding p2_def by (subst (10) complex_surj[symmetric],auto)
    subgoal unfolding p3_def by (subst (10) complex_surj[symmetric],auto simp add:minus_complex.code)
    subgoal unfolding p4_def by (subst (10) complex_surj[symmetric],auto)
    done    
  show ?thesis 
    apply (subst proots_rectangle_code1)
    apply (unfold no_proots_line_code Let_def)
    apply (fold p1_def p2_def p3_def p4_def pI1_def pR1_def pI2_def pR2_def pI3_def pR3_def
          pI4_def pR4_def gc1_def gc2_def gc3_def gc4_def more_folds)
    apply (fold sms_def)
    by presburger 
qed  

subsection \<open>proots on a half plane\<close>

text \<open>the number of roots of polynomial @{term p}, counted with multiplicity,
   on the left half plane of the vector @{term "b-a"}.\<close>
definition proots_half ::"complex poly \<Rightarrow> complex \<Rightarrow> complex \<Rightarrow> int" where
  "proots_half p a b = proots_count p {w. Im ((w-a) / (b-a)) > 0}"    
  
  
definition proots_upper ::"complex poly \<Rightarrow> int" where
  "proots_upper p= proots_count p {z. Im z>0}"

lemma proots_half_empty:
  assumes "a=b"
  shows "proots_half p a b = 0"  
unfolding proots_half_def using assms by auto  
    
lemma proots_half_proots_upper:
  assumes "a\<noteq>b" "p\<noteq>0"
  shows "proots_half p a b= proots_upper (pcompose p [:a, (b-a):])"
proof -
  define q where "q=[:a, (b - a):]"
  define f where "f=(\<lambda>x. (b-a)*x+ a)"
  have "(\<Sum>r\<in>proots_within p {w. Im ((w-a) / (b-a)) > 0}. order r p) 
      = (\<Sum>r\<in>proots_within (p \<circ>\<^sub>p q) {z. 0 < Im z}. order r (p \<circ>\<^sub>pq))"
  proof (rule sum.reindex_cong[of f])
    have "inj f"
      using assms unfolding f_def inj_on_def by fastforce
    then show "inj_on f (proots_within (p \<circ>\<^sub>p q) {z. 0 < Im z})"
      by (elim inj_on_subset,auto)
  next
    show "proots_within p {w. Im ((w-a) / (b-a)) > 0} = f ` proots_within (p \<circ>\<^sub>p q) {z. 0 < Im z}"
    proof safe
      fix x assume x_asm:"x \<in> proots_within p {w. Im ((w-a) / (b-a)) > 0}"
      define xx where "xx=(x -a) / (b - a)"
      have "poly (p \<circ>\<^sub>p q) xx = 0"  
        unfolding q_def xx_def poly_pcompose using assms x_asm by auto
      moreover have "Im xx > 0" 
        unfolding xx_def using x_asm by auto
      ultimately have "xx \<in> proots_within (p \<circ>\<^sub>p q) {z. 0 < Im z}" by auto
      then show "x \<in> f ` proots_within (p \<circ>\<^sub>p q) {z. 0 < Im z}" 
        apply (intro rev_image_eqI[of xx])
        unfolding f_def xx_def using assms by auto
    next
      fix x assume "x \<in> proots_within (p \<circ>\<^sub>p q) {z. 0 < Im z}"
      then show "f x \<in> proots_within p {w. 0 < Im ((w-a) / (b - a))}" 
        unfolding f_def q_def using assms 
        apply (auto simp add:poly_pcompose)
        by (auto simp add:algebra_simps)
    qed
  next
    fix x assume "x \<in> proots_within (p \<circ>\<^sub>p q) {z. 0 < Im z}"
    show "order (f x) p = order x (p \<circ>\<^sub>p q)" using \<open>p\<noteq>0\<close>
    proof (induct p rule:poly_root_induct_alt)
      case 0
      then show ?case by simp
    next
      case (no_proots p)
      have "order (f x) p = 0"
        apply (rule order_0I)        
        using no_proots by auto
      moreover have "order x (p \<circ>\<^sub>p q) = 0"
        apply (rule order_0I)
        unfolding poly_pcompose q_def using no_proots by auto
      ultimately show ?case by auto
    next
      case (root c p)
      have "order (f x) ([:- c, 1:] * p) = order (f x) [:-c,1:] + order (f x) p" 
        apply (subst order_mult)
        using root by auto
      also have "... =  order x ([:- c, 1:] \<circ>\<^sub>p q) +  order x (p \<circ>\<^sub>p q)" 
      proof -
        have "order (f x) [:- c, 1:] = order x ([:- c, 1:] \<circ>\<^sub>p q)" 
        proof (cases "f x=c")
          case True
          have "[:- c, 1:] \<circ>\<^sub>p q = smult (b-a) [:-x,1:]"
            using True unfolding q_def f_def pcompose_pCons by auto
          then have "order x ([:- c, 1:] \<circ>\<^sub>p q) = order x (smult (b-a) [:-x,1:])"
            by auto
          then have "order x ([:- c, 1:] \<circ>\<^sub>p q) = 1"
            apply (subst (asm) order_smult)
            using assms order_power_n_n[of _ 1,simplified] by auto   
          moreover have "order (f x) [:- c, 1:] = 1"
            using True order_power_n_n[of _ 1,simplified] by auto
          ultimately show ?thesis by auto
        next
          case False
          have "order (f x) [:- c, 1:] = 0"
            apply (rule order_0I)
            using False unfolding f_def by auto
          moreover have "order x ([:- c, 1:] \<circ>\<^sub>p q) = 0"
            apply (rule order_0I)
            using False unfolding f_def q_def poly_pcompose by auto
          ultimately show ?thesis by auto
        qed
        moreover have "order (f x) p = order x (p \<circ>\<^sub>p q)"
          apply (rule root)
          using root by auto 
        ultimately show ?thesis by auto
      qed
      also have "... = order x (([:- c, 1:] * p) \<circ>\<^sub>p q)" 
        unfolding pcompose_mult
        apply (subst order_mult)
        subgoal unfolding q_def using assms(1) pcompose_eq_0 root.prems by fastforce  
        by simp
      finally show ?case .
    qed
  qed
  then show ?thesis unfolding proots_half_def proots_upper_def proots_count_def q_def
    by auto
qed    
     
lemma Im_Ln_tendsto_at_top: "((\<lambda>x. Im (Ln (Complex a x))) \<longlongrightarrow> pi/2 ) at_top " 
proof (cases "a=0")
  case False
  define f where "f=(\<lambda>x. if a>0 then arctan (x/a) else arctan (x/a) + pi)"
  define g where "g=(\<lambda>x. Im (Ln (Complex a x)))"
  have "(f \<longlongrightarrow> pi / 2) at_top"
  proof (cases "a>0")
    case True
    then have "(f \<longlongrightarrow> pi / 2) at_top \<longleftrightarrow> ((\<lambda>x. arctan (x * inverse a)) \<longlongrightarrow> pi / 2) at_top"
      unfolding f_def field_class.field_divide_inverse by auto
    also have "... \<longleftrightarrow> (arctan \<longlongrightarrow> pi / 2) at_top"
      apply (subst filterlim_at_top_linear_iff[of "inverse a" arctan 0 "nhds (pi/2)",simplified])
      using True by auto
    also have "..." using tendsto_arctan_at_top .
    finally show ?thesis .    
  next
    case False
    then have "(f \<longlongrightarrow> pi / 2) at_top \<longleftrightarrow> ((\<lambda>x. arctan (x * inverse a) + pi) \<longlongrightarrow> pi / 2) at_top"
      unfolding f_def field_class.field_divide_inverse by auto
    also have "... \<longleftrightarrow> ((\<lambda>x. arctan (x * inverse a)) \<longlongrightarrow> - pi / 2) at_top"
      apply (subst tendsto_add_const_iff[of "-pi",symmetric])
      by auto
    also have "... \<longleftrightarrow> (arctan \<longlongrightarrow> - pi / 2) at_bot"
      apply (subst filterlim_at_top_linear_iff[of "inverse a" arctan 0,simplified])
      using False \<open>a\<noteq>0\<close> by auto
    also have "..." using tendsto_arctan_at_bot by simp
    finally show ?thesis .
  qed
  moreover have "\<forall>\<^sub>F x in at_top. f x = g x"
    unfolding f_def g_def using \<open>a\<noteq>0\<close>
    apply (subst Im_Ln_eq)
    subgoal for x using Complex_eq_0 by blast
    subgoal unfolding eventually_at_top_linorder by auto
    done
  ultimately show ?thesis 
    using tendsto_cong[of f g at_top] unfolding g_def by auto
next
  case True
  show ?thesis
    apply (rule Lim_eventually)
    apply (rule eventually_at_top_linorderI[of 1])
    using True by (subst Im_Ln_eq,auto simp add:Complex_eq_0) 
qed
  

lemma Im_Ln_tendsto_at_bot: "((\<lambda>x. Im (Ln (Complex a x))) \<longlongrightarrow> - pi/2 ) at_bot " 
proof (cases "a=0")
  case False
  define f where "f=(\<lambda>x. if a>0 then arctan (x/a) else arctan (x/a) - pi)"
  define g where "g=(\<lambda>x. Im (Ln (Complex a x)))"
  have "(f \<longlongrightarrow> - pi / 2) at_bot"
  proof (cases "a>0")
    case True
    then have "(f \<longlongrightarrow> - pi / 2) at_bot \<longleftrightarrow> ((\<lambda>x. arctan (x * inverse a)) \<longlongrightarrow> - pi / 2) at_bot"
      unfolding f_def field_class.field_divide_inverse by auto
    also have "... \<longleftrightarrow> (arctan \<longlongrightarrow> - pi / 2) at_bot"
      apply (subst filterlim_at_bot_linear_iff[of "inverse a" arctan 0,simplified])
      using True by auto
    also have "..." using tendsto_arctan_at_bot by simp
    finally show ?thesis .    
  next
    case False
    then have "(f \<longlongrightarrow> - pi / 2) at_bot \<longleftrightarrow> ((\<lambda>x. arctan (x * inverse a) - pi) \<longlongrightarrow> - pi / 2) at_bot"
      unfolding f_def field_class.field_divide_inverse by auto
    also have "... \<longleftrightarrow> ((\<lambda>x. arctan (x * inverse a)) \<longlongrightarrow> pi / 2) at_bot"
      apply (subst tendsto_add_const_iff[of "pi",symmetric])
      by auto
    also have "... \<longleftrightarrow> (arctan \<longlongrightarrow> pi / 2) at_top"
      apply (subst filterlim_at_bot_linear_iff[of "inverse a" arctan 0,simplified])
      using False \<open>a\<noteq>0\<close> by auto
    also have "..." using tendsto_arctan_at_top by simp
    finally show ?thesis .
  qed
  moreover have "\<forall>\<^sub>F x in at_bot. f x = g x"
    unfolding f_def g_def using \<open>a\<noteq>0\<close>
    apply (subst Im_Ln_eq)
    subgoal for x using Complex_eq_0 by blast
    subgoal unfolding eventually_at_bot_linorder by (auto intro:exI[where x="-1"])
    done
  ultimately show ?thesis 
    using tendsto_cong[of f g at_bot] unfolding g_def by auto
next
  case True
  show ?thesis
    apply (rule Lim_eventually)  
    apply (rule eventually_at_bot_linorderI[of "-1"])
    using True by (subst Im_Ln_eq,auto simp add:Complex_eq_0)
qed
  
lemma Re_winding_number_tendsto_part_circlepath:
  shows "((\<lambda>r. Re (winding_number (part_circlepath z0 r 0 pi ) a)) \<longlongrightarrow> 1/2 ) at_top" 
proof (cases "Im z0\<le>Im a")
  case True
  define g1 where "g1=(\<lambda>r. part_circlepath z0 r 0 pi)"
  define g2 where "g2=(\<lambda>r. part_circlepath z0 r pi (2*pi))"
  define f1 where "f1=(\<lambda>r. Re (winding_number (g1 r ) a))"
  define f2 where "f2=(\<lambda>r. Re (winding_number (g2 r) a))"
  have "(f2 \<longlongrightarrow> 1/2 ) at_top" 
  proof -
    define h1 where "h1 = (\<lambda>r. Im (Ln (Complex ( Im a-Im z0) (Re z0 - Re a + r))))"
    define h2 where "h2= (\<lambda>r. Im (Ln (Complex (  Im a -Im z0) (Re z0 - Re a - r))))"
    have "\<forall>\<^sub>F x in at_top. f2 x = (h1 x - h2 x) / (2 * pi)"
    proof (rule eventually_at_top_linorderI[of "cmod (a-z0) + 1"])
      fix r assume asm:"r \<ge> cmod (a - z0) + 1"
      have "Im p \<le> Im a" when "p\<in>path_image (g2 r)" for p
      proof -
        obtain t where p_def:"p=z0 + of_real r * exp (\<i> * of_real t)" and "pi\<le>t" "t\<le>2*pi"
          using \<open>p\<in>path_image (g2 r)\<close> 
          unfolding g2_def path_image_part_circlepath[of pi "2*pi",simplified]  
          by auto
        then have "Im p=Im z0 + sin t * r" by (auto simp add:Im_exp)
        also have "... \<le> Im z0"
        proof -
          have "sin t\<le>0" using \<open>pi\<le>t\<close> \<open>t\<le>2*pi\<close> sin_le_zero by fastforce
          moreover have "r\<ge>0" 
            using asm by (metis add.inverse_inverse add.left_neutral add_uminus_conv_diff
                diff_ge_0_iff_ge norm_ge_zero order_trans zero_le_one)
          ultimately have "sin t * r\<le>0" using mult_le_0_iff by blast
          then show ?thesis by auto
        qed
        also have "... \<le> Im a" using True .
        finally show ?thesis .
      qed
      moreover have "valid_path (g2 r)" unfolding g2_def by auto
      moreover have "a \<notin> path_image (g2 r)"
        unfolding g2_def 
        apply (rule not_on_circlepathI)
        using asm by auto  
      moreover have [symmetric]:"Im (Ln (\<i> * pathfinish (g2 r) - \<i> * a)) = h1 r"
        unfolding h1_def g2_def
        apply (simp only:pathfinish_pathstart_partcirclepath_simps)
        apply (subst (4 10) complex_eq)
        by (auto simp add:algebra_simps Complex_eq)
      moreover have [symmetric]:"Im (Ln (\<i> * pathstart (g2 r) - \<i> * a)) = h2 r"
        unfolding h2_def g2_def
        apply (simp only:pathfinish_pathstart_partcirclepath_simps)
        apply (subst (4 10) complex_eq)
        by (auto simp add:algebra_simps Complex_eq)
      ultimately show "f2 r = (h1 r - h2 r) / (2 * pi)" 
        unfolding f2_def 
        apply (subst Re_winding_number_half_lower)
        by (auto simp add:exp_Euler algebra_simps)
    qed  
    moreover have "((\<lambda>x. (h1 x - h2 x) / (2 * pi)) \<longlongrightarrow> 1/2 ) at_top"
    proof -
      have "(h1 \<longlongrightarrow> pi/2) at_top"
        unfolding h1_def
        apply (subst filterlim_at_top_linear_iff[of 1 _ "Re a - Re z0" ,simplified,symmetric]) 
        using Im_Ln_tendsto_at_top by (simp del:Complex_eq)
      moreover have "(h2 \<longlongrightarrow> - pi/2) at_top"  
        unfolding h2_def
        apply (subst filterlim_at_bot_linear_iff[of "- 1" _ "- Re a + Re z0" ,simplified,symmetric])  
        using Im_Ln_tendsto_at_bot by (simp del:Complex_eq)  
      ultimately have "((\<lambda>x. h1 x- h2 x) \<longlongrightarrow> pi) at_top"    
        by (auto intro: tendsto_eq_intros)
      then show ?thesis
        by (auto intro: tendsto_eq_intros)
    qed
    ultimately show ?thesis by (auto dest:tendsto_cong)
  qed
  moreover have "\<forall>\<^sub>F r in at_top. f2 r = 1 - f1 r"
  proof (rule eventually_at_top_linorderI[of "cmod (a-z0) + 1"])
    fix r assume asm:"r \<ge> cmod (a - z0) + 1"
    have "f1 r + f2 r = Re(winding_number (g1 r +++ g2 r) a)" 
      unfolding f1_def f2_def g1_def g2_def
      apply (subst winding_number_join)
      using asm by (auto intro!:not_on_circlepathI)
    also have "... = Re(winding_number (circlepath z0 r) a)"
    proof -
      have "g1 r +++ g2 r = circlepath z0 r"
        unfolding circlepath_def g1_def g2_def joinpaths_def part_circlepath_def linepath_def
        by (auto simp add:field_simps)
      then show ?thesis by auto
    qed
    also have "... = 1"
    proof -
      have "winding_number (circlepath z0 r) a = 1"
        apply (rule winding_number_circlepath)
        using asm by auto
      then show ?thesis by auto
    qed
    finally have "f1 r+f2 r=1" .
    then show " f2 r = 1 - f1 r" by auto
  qed
  ultimately have "((\<lambda>r. 1 - f1 r) \<longlongrightarrow> 1/2 ) at_top"
    using tendsto_cong[of f2 "\<lambda>r. 1 - f1 r" at_top] by auto
  then have "(f1 \<longlongrightarrow> 1/2 ) at_top" 
    apply (rule_tac tendsto_minus_cancel)
    apply (subst tendsto_add_const_iff[of 1,symmetric])
    by auto
  then show ?thesis unfolding f1_def g1_def by auto
next
  case False
  define g where "g=(\<lambda>r. part_circlepath z0 r 0 pi)"
  define f where "f=(\<lambda>r. Re (winding_number (g r) a))"
  have "(f \<longlongrightarrow> 1/2 ) at_top" 
  proof -
    define h1 where "h1 = (\<lambda>r. Im (Ln (Complex ( Im z0-Im a) (Re a - Re z0 + r))))"
    define h2 where "h2= (\<lambda>r. Im (Ln (Complex (  Im z0 -Im a ) (Re a - Re z0 - r))))"
    have "\<forall>\<^sub>F x in at_top. f x = (h1 x - h2 x) / (2 * pi)"
    proof (rule eventually_at_top_linorderI[of "cmod (a-z0) + 1"])
      fix r assume asm:"r \<ge> cmod (a - z0) + 1"
      have "Im p \<ge> Im a" when "p\<in>path_image (g r)" for p
      proof -
        obtain t where p_def:"p=z0 + of_real r * exp (\<i> * of_real t)" and "0\<le>t" "t\<le>pi"
          using \<open>p\<in>path_image (g r)\<close> 
          unfolding g_def path_image_part_circlepath[of 0 pi,simplified]  
          by auto
        then have "Im p=Im z0 + sin t * r" by (auto simp add:Im_exp)    
        moreover have "sin t * r\<ge>0"
        proof -
          have "sin t\<ge>0" using \<open>0\<le>t\<close> \<open>t\<le>pi\<close> sin_ge_zero by fastforce
          moreover have "r\<ge>0" 
            using asm by (metis add.inverse_inverse add.left_neutral add_uminus_conv_diff
                diff_ge_0_iff_ge norm_ge_zero order_trans zero_le_one)
          ultimately have "sin t * r\<ge>0" by simp
          then show ?thesis by auto
        qed
        ultimately show ?thesis using False by auto
      qed
      moreover have "valid_path (g r)" unfolding g_def by auto
      moreover have "a \<notin> path_image (g r)"
        unfolding g_def 
        apply (rule not_on_circlepathI)
        using asm by auto  
      moreover have [symmetric]:"Im (Ln (\<i> * a - \<i> * pathfinish (g r))) = h1 r"
        unfolding h1_def g_def
        apply (simp only:pathfinish_pathstart_partcirclepath_simps)
        apply (subst (4 9) complex_eq)
        by (auto simp add:algebra_simps Complex_eq)
      moreover have [symmetric]:"Im (Ln (\<i> * a - \<i> * pathstart (g r))) = h2 r"
        unfolding h2_def g_def
        apply (simp only:pathfinish_pathstart_partcirclepath_simps)
        apply (subst (4 9) complex_eq)
        by (auto simp add:algebra_simps Complex_eq)
      ultimately show "f r = (h1 r - h2 r) / (2 * pi)" 
        unfolding f_def 
        apply (subst Re_winding_number_half_upper) 
        by (auto simp add:exp_Euler algebra_simps)
    qed  
    moreover have "((\<lambda>x. (h1 x - h2 x) / (2 * pi)) \<longlongrightarrow> 1/2 ) at_top"
    proof -
      have "(h1 \<longlongrightarrow> pi/2) at_top"
        unfolding h1_def
        apply (subst filterlim_at_top_linear_iff[of 1 _ "- Re a + Re z0" ,simplified,symmetric]) 
        using Im_Ln_tendsto_at_top by (simp del:Complex_eq)
      moreover have "(h2 \<longlongrightarrow> - pi/2) at_top"  
        unfolding h2_def
        apply (subst filterlim_at_bot_linear_iff[of "- 1" _ "Re a - Re z0" ,simplified,symmetric])  
        using Im_Ln_tendsto_at_bot by (simp del:Complex_eq)  
      ultimately have "((\<lambda>x. h1 x- h2 x) \<longlongrightarrow> pi) at_top"    
        by (auto intro: tendsto_eq_intros)
      then show ?thesis
        by (auto intro: tendsto_eq_intros)
    qed
    ultimately show ?thesis by (auto dest:tendsto_cong)
  qed
  then show ?thesis unfolding f_def g_def by auto
qed
  
lemma not_image_at_top_poly_part_circlepath:
  assumes "degree p>0"
  shows "\<forall>\<^sub>F r in at_top. b\<notin>path_image (poly p o part_circlepath z0 r st tt)"  
proof -
  have "finite (proots (p-[:b:]))" 
    apply (rule finite_proots)
    using assms by auto  
  from finite_ball_include[OF this]
  obtain R::real where "R>0" and R_ball:"proots (p-[:b:]) \<subseteq> ball z0 R" by auto
  show ?thesis
  proof (rule eventually_at_top_linorderI[of R])
    fix r assume "r\<ge>R"    
    show  "b\<notin>path_image (poly p o part_circlepath z0 r st tt)"
      unfolding path_image_compose 
    proof clarify
      fix x assume asm:"b = poly p x" "x \<in> path_image (part_circlepath z0 r st tt)"
      then have "x\<in>proots (p-[:b:])" unfolding proots_def by auto
      then have "x\<in>ball z0 r" using R_ball \<open>r\<ge>R\<close> by auto  
      then have "cmod (x- z0) < r" 
        by (simp add: dist_commute dist_norm)
      moreover have "cmod (x - z0) = r"
        using asm(2) in_path_image_part_circlepath \<open>R>0\<close> \<open>r\<ge>R\<close>  by auto  
      ultimately show False by auto
    qed
  qed
qed  

lemma not_image_poly_part_circlepath:
  assumes "degree p>0"
  shows "\<exists>r>0.  b\<notin>path_image (poly p o part_circlepath z0 r st tt)"
proof -
  have "finite (proots (p-[:b:]))" 
    apply (rule finite_proots)
    using assms by auto  
  from finite_ball_include[OF this]
  obtain r::real where "r>0" and r_ball:"proots (p-[:b:]) \<subseteq> ball z0 r" by auto
  have "b\<notin>path_image (poly p o part_circlepath z0 r st tt)"
    unfolding path_image_compose 
  proof clarify
    fix x assume asm:"b = poly p x" "x \<in> path_image (part_circlepath z0 r st tt)"
    then have "x\<in>proots (p-[:b:])" unfolding proots_def by auto
    then have "x\<in>ball z0 r" using r_ball by auto  
    then have "cmod (x- z0) < r" 
      by (simp add: dist_commute dist_norm)
    moreover have "cmod (x - z0) = r"
      using asm(2) in_path_image_part_circlepath \<open>r>0\<close> by auto  
    ultimately show False by auto
  qed
  then show ?thesis using \<open>r>0\<close> by blast
qed
   
lemma Re_winding_number_poly_part_circlepath:
  assumes "degree p>0"
  shows "((\<lambda>r. Re (winding_number (poly p o part_circlepath z0 r 0 pi) 0)) \<longlongrightarrow> degree p/2 ) at_top"
using assms
proof (induct rule:poly_root_induct_alt)
  case 0
  then show ?case by auto
next
  case (no_proots p)
  then have False 
    using Fundamental_Theorem_Algebra.fundamental_theorem_of_algebra constant_degree neq0_conv
    by blast
  then show ?case by auto
next
  case (root a p)
  define g where "g = (\<lambda>r. part_circlepath z0 r 0 pi)"
  define q where "q=[:- a, 1:] * p"
  define w where "w = (\<lambda>r. winding_number (poly q \<circ> g r) 0)"
  have ?case when "degree p=0"
  proof -
    obtain pc where pc_def:"p=[:pc:]" using \<open>degree p = 0\<close> degree_eq_zeroE by blast
    then have "pc\<noteq>0" using root(2) by auto
    have "\<forall>\<^sub>F r in at_top. Re (w r) = Re (winding_number (g r) a)" 
    proof (rule eventually_at_top_linorderI[of "cmod (( pc * a) / pc - z0) + 1"])
      fix r::real assume asm:"cmod ((pc * a) / pc - z0) + 1 \<le> r"
      have "w r =  winding_number ((\<lambda>x. pc*x - pc*a) \<circ> (g r)) 0"
        unfolding w_def pc_def g_def q_def
        apply auto
        by (metis (no_types, hide_lams) add.right_neutral mult.commute mult_zero_right 
            poly_0 poly_pCons uminus_add_conv_diff)
      also have "... =  winding_number (g r) a "
        apply (subst winding_number_comp_linear[where b="-pc*a",simplified])
        subgoal using \<open>pc\<noteq>0\<close> .
        subgoal unfolding g_def by auto
        subgoal unfolding g_def
          apply (rule not_on_circlepathI)
          using asm by auto
        subgoal using \<open>pc\<noteq>0\<close> by (auto simp add:field_simps)
        done
      finally have "w r = winding_number (g r) a " .
      then show "Re (w r) = Re (winding_number (g r) a)" by simp
    qed
    moreover have "((\<lambda>r. Re (winding_number (g r) a)) \<longlongrightarrow> 1/2) at_top"
      using Re_winding_number_tendsto_part_circlepath unfolding g_def by auto
    ultimately have "((\<lambda>r. Re (w r)) \<longlongrightarrow> 1/2) at_top"
      by (auto dest!:tendsto_cong)
    moreover have "degree ([:- a, 1:] * p) = 1" unfolding pc_def using \<open>pc\<noteq>0\<close> by auto
    ultimately show ?thesis unfolding w_def g_def comp_def q_def by simp
  qed
  moreover have ?case when "degree p>0"
  proof -
    have "\<forall>\<^sub>F r in at_top. 0 \<notin> path_image (poly q \<circ> g r)"  
      unfolding g_def
      apply (rule not_image_at_top_poly_part_circlepath)
      unfolding q_def using root.prems by blast
    then have "\<forall>\<^sub>F r in at_top. Re (w r) = Re (winding_number (g r) a) 
              + Re (winding_number (poly p \<circ> g r) 0)"
    proof (rule eventually_mono)
      fix r assume asm:"0 \<notin> path_image (poly q \<circ> g r)"
      define cc where "cc= 1 / (of_real (2 * pi) * \<i>)"  
      define pf where "pf=(\<lambda>w. deriv (poly p) w / poly p w)"
      define af where "af=(\<lambda>w. 1/(w-a))"  
      have "w r = cc * contour_integral (g r) (\<lambda>w. deriv (poly q) w / poly q w)"
        unfolding w_def 
        apply (subst winding_number_comp[of UNIV,simplified])
        using asm unfolding g_def cc_def  by auto
      also have "... = cc * contour_integral (g r) (\<lambda>w. deriv (poly p) w / poly p w + 1/(w-a))"  
      proof -
        have "contour_integral (g r) (\<lambda>w. deriv (poly q) w / poly q w) 
            = contour_integral (g r) (\<lambda>w. deriv (poly p) w / poly p w + 1/(w-a))"
        proof (rule contour_integral_eq)   
          fix x assume "x \<in> path_image (g r)"  
          have "deriv (poly q) x = deriv (poly p) x * (x-a) + poly p x" 
          proof -
            have "poly q = (\<lambda>x. (x-a) * poly p x)" 
              apply (rule ext)
              unfolding q_def by (auto simp add:algebra_simps) 
            then show ?thesis    
              apply simp
              apply (subst deriv_mult[of "\<lambda>x. x- a" _ "poly p"])
              by (auto intro:derivative_intros)
          qed
          moreover have "poly p x\<noteq>0 \<and> x-a\<noteq>0" 
          proof (rule ccontr)
            assume "\<not> (poly p x \<noteq> 0 \<and> x - a \<noteq> 0)"
            then have "poly q x=0" unfolding q_def by auto  
            then have "0\<in>poly q ` path_image (g r)"
              using \<open>x \<in> path_image (g r)\<close> by auto
            then show False using \<open>0 \<notin> path_image (poly q \<circ> g r)\<close> 
              unfolding path_image_compose by auto
          qed
          ultimately show "deriv (poly q) x / poly q x = deriv (poly p) x / poly p x + 1 / (x - a)" 
            unfolding q_def by (auto simp add:field_simps)  
        qed
        then show ?thesis by auto
      qed
      also have "... = cc * contour_integral (g r) (\<lambda>w. deriv (poly p) w / poly p w) 
          + cc * contour_integral (g r) (\<lambda>w. 1/(w-a))"  
      proof (subst contour_integral_add)
        have "continuous_on (path_image (g r)) (\<lambda>w. deriv (poly p) w)"
          unfolding deriv_pderiv by (intro continuous_intros)  
        moreover have "\<forall>w\<in>path_image (g r). poly p w \<noteq> 0" 
          using asm unfolding q_def path_image_compose by auto
        ultimately show "(\<lambda>w. deriv (poly p) w / poly p w) contour_integrable_on g r" 
          unfolding g_def
          by (auto intro!: contour_integrable_continuous_part_circlepath continuous_intros)
        show "(\<lambda>w. 1 / (w - a)) contour_integrable_on g r" 
          apply (rule contour_integrable_inversediff)
          subgoal unfolding g_def by auto
          subgoal using asm unfolding q_def path_image_compose by auto
          done
      qed (auto simp add:algebra_simps)
      also have "... =  winding_number (g r) a +  winding_number (poly p o g r) 0"
      proof -
        have "winding_number (poly p o g r) 0
            = cc * contour_integral (g r) (\<lambda>w. deriv (poly p) w / poly p w)"
          apply (subst winding_number_comp[of UNIV,simplified])
          using \<open>0 \<notin> path_image (poly q \<circ> g r)\<close> unfolding path_image_compose q_def g_def cc_def
          by auto
        moreover have "winding_number (g r) a = cc * contour_integral (g r) (\<lambda>w. 1/(w-a))"
          apply (subst winding_number_valid_path)
          using \<open>0 \<notin> path_image (poly q \<circ> g r)\<close> unfolding path_image_compose q_def g_def cc_def
          by auto
        ultimately show ?thesis by auto
      qed
      finally show "Re (w r) = Re (winding_number (g r) a) + Re (winding_number (poly p \<circ> g r) 0)"
        by auto
    qed
    moreover have "((\<lambda>r. Re (winding_number (g r) a) 
              + Re (winding_number (poly p \<circ> g r) 0)) \<longlongrightarrow> degree q / 2) at_top" 
    proof -
      have "((\<lambda>r. Re (winding_number (g r) a)) \<longlongrightarrow>1 / 2) at_top" 
        unfolding g_def by (rule Re_winding_number_tendsto_part_circlepath)  
      moreover have "((\<lambda>r. Re (winding_number (poly p \<circ> g r) 0)) \<longlongrightarrow> degree p / 2) at_top"
        unfolding g_def by (rule root(1)[OF that])
      moreover have "degree q = degree p + 1" 
        unfolding q_def
        apply (subst degree_mult_eq)
        using that by auto
      ultimately show ?thesis
        by (simp add: tendsto_add add_divide_distrib)
    qed
    ultimately have "((\<lambda>r. Re (w r)) \<longlongrightarrow> degree q/2) at_top"
      by (auto dest!:tendsto_cong)
    then show ?thesis unfolding w_def q_def g_def by blast
  qed
  ultimately show ?case by blast
qed     

lemma Re_winding_number_poly_linepth:
  fixes pp::"complex poly"
  defines "g \<equiv> (\<lambda>r. poly pp o linepath (-r) (of_real r))"
  assumes "lead_coeff pp=1" and no_real_zero:"\<forall>x\<in>proots pp. Im x\<noteq>0"
  shows "((\<lambda>r. 2*Re (winding_number (g r) 0) + cindex_pathE (g r) 0 ) \<longlongrightarrow> 0 ) at_top" 
proof -
  define p where "p=map_poly Re pp" 
  define q where "q=map_poly Im pp"
  define f where "f=(\<lambda>t. poly q t / poly p t)"
  have sgnx_top:"sgnx (poly p) at_top = 1"
    unfolding sgnx_poly_at_top sgn_pos_inf_def p_def using \<open>lead_coeff pp=1\<close>
    by (subst lead_coeff_map_poly_nz,auto)
  have not_g_image:"0 \<notin> path_image (g r)" for r
  proof (rule ccontr)
    assume "\<not> 0 \<notin> path_image (g r)"
    then obtain x where "poly pp x=0" "x\<in>closed_segment (- of_real r) (of_real r)"
      unfolding g_def path_image_compose of_real_linepath by auto
    then have "Im x=0" "x\<in>proots pp" 
      using closed_segment_imp_Re_Im(2) unfolding proots_def by fastforce+
    then show False using \<open>\<forall>x\<in>proots pp. Im x\<noteq>0\<close> by auto
  qed    
  have arctan_f_tendsto:"((\<lambda>r. (arctan (f r) -  arctan (f (-r))) / pi) \<longlongrightarrow> 0) at_top"
  proof (cases "degree p>0")
    case True
    have "degree p>degree q" 
    proof -
      have "degree p=degree pp"
        unfolding p_def using \<open>lead_coeff pp=1\<close>
        by (auto intro:map_poly_degree_eq)
      moreover then have "degree q<degree pp"
        unfolding q_def using \<open>lead_coeff pp=1\<close> True
        by (auto intro!:map_poly_degree_less)
      ultimately show ?thesis by auto
    qed
    then have "(f \<longlongrightarrow> 0) at_infinity"
      unfolding f_def using poly_divide_tendsto_0_at_infinity by auto
    then have "(f \<longlongrightarrow> 0) at_bot" "(f \<longlongrightarrow> 0) at_top"
      by (auto elim!:filterlim_mono simp add:at_top_le_at_infinity at_bot_le_at_infinity)
    then have "((\<lambda>r. arctan (f r))\<longlongrightarrow> 0) at_top" "((\<lambda>r. arctan (f (-r)))\<longlongrightarrow> 0) at_top"
      apply -
      subgoal by (auto intro:tendsto_eq_intros)
      subgoal 
        apply (subst tendsto_compose_filtermap[of _ uminus,unfolded comp_def])
        by (auto intro:tendsto_eq_intros simp add:at_bot_mirror[symmetric])
      done
    then show ?thesis 
      by (auto intro:tendsto_eq_intros)
  next
    case False
    obtain c where "f=(\<lambda>r. c)"
    proof -
      have "degree p=0" using False by auto
      moreover have "degree q\<le>degree p"
      proof -
        have "degree p=degree pp" 
          unfolding p_def using \<open>lead_coeff pp=1\<close>
          by (auto intro:map_poly_degree_eq)
        moreover have "degree q\<le>degree pp"
          unfolding q_def by simp
        ultimately show ?thesis by auto
      qed
      ultimately have "degree q=0" by simp
      then obtain pa qa where "p=[:pa:]" "q=[:qa:]"
        using \<open>degree p=0\<close> by (meson degree_eq_zeroE)
      then show ?thesis using that unfolding f_def by auto
    qed
    then show ?thesis by auto
  qed
  have [simp]:"valid_path (g r)" "path (g r)" "finite_ReZ_segments (g r) 0" for r
  proof -
    show "valid_path (g r)" unfolding g_def
      apply (rule valid_path_compose_holomorphic[where S=UNIV])
      by (auto simp add:of_real_linepath)
    then show "path (g r)" using valid_path_imp_path by auto
    show "finite_ReZ_segments (g r) 0"
      unfolding g_def of_real_linepath using finite_ReZ_segments_poly_linepath by simp
  qed
  have g_f_eq:"Im (g r t) / Re (g r t) = (f o (\<lambda>x. 2*r*x - r)) t" for r t 
  proof -
    have "Im (g r t) / Re (g r t) = Im ((poly pp o of_real o (\<lambda>x. 2*r*x - r)) t) 
        / Re ((poly pp o of_real o (\<lambda>x. 2*r*x - r)) t)"
      unfolding g_def linepath_def comp_def 
      by (auto simp add:algebra_simps)
    also have "... = (f o (\<lambda>x. 2*r*x - r)) t"
      unfolding comp_def
      by (simp only:Im_poly_of_real diff_0_right Re_poly_of_real f_def q_def p_def)
    finally show ?thesis .
  qed

  have ?thesis when "proots p={}"
  proof -
    have "\<forall>\<^sub>Fr in at_top. 2 * Re (winding_number (g r) 0) + cindex_pathE (g r) 0
        = (arctan (f r) -  arctan (f (-r))) / pi"
    proof (rule eventually_at_top_linorderI[of 1])
      fix r::real assume "r\<ge>1"
      have image_pos:"\<forall>p\<in>path_image (g r).  0<Re p "
      proof (rule ccontr)
        assume "\<not> (\<forall>p\<in>path_image (g r). 0 < Re p)"
        then obtain t where "poly p t\<le>0" 
          unfolding g_def path_image_compose of_real_linepath p_def 
          using Re_poly_of_real
          apply (simp add:closed_segment_def)
          by (metis not_less of_real_def real_vector.scale_scale scaleR_left_diff_distrib)  
        moreover have False when "poly p t<0"    
        proof -
          have "sgnx (poly p) (at_right t) = -1"  
            using sgnx_poly_nz that by auto
          then obtain x where "x>t" "poly p x = 0"
            using sgnx_at_top_IVT[of p t] sgnx_top by auto
          then have "x\<in>proots p" unfolding proots_def by auto
          then show False using \<open>proots p={}\<close> by auto
        qed
        moreover have False when "poly p t=0"
          using \<open>proots p={}\<close> that unfolding proots_def by auto
        ultimately show False by linarith
      qed
      have "Re (winding_number (g r) 0) = (Im (Ln (pathfinish (g r))) - Im (Ln (pathstart (g r)))) 
          / (2 * pi)"
        apply (rule Re_winding_number_half_right[of "g r" 0,simplified])
        subgoal using image_pos by auto
        subgoal by (auto simp add:not_g_image)
        done
      also have "... = (arctan (f r) - arctan (f (-r)))/(2*pi)"
      proof -
        have "Im (Ln (pathfinish (g r))) = arctan (f r)"
        proof -
          have "Re (pathfinish (g r)) > 0"
            by (auto intro: image_pos[rule_format])
          then have "Im (Ln (pathfinish (g r))) 
              = arctan (Im (pathfinish (g r)) / Re (pathfinish (g r)))" 
            by (subst Im_Ln_eq,auto)
          also have "... = arctan (f r)"
            unfolding path_defs by (subst g_f_eq,auto)
          finally show ?thesis .
        qed
        moreover have "Im (Ln (pathstart (g r))) = arctan (f (-r))"
        proof -
          have "Re (pathstart (g r)) > 0"
            by (auto intro: image_pos[rule_format])
          then have "Im (Ln (pathstart (g r))) 
              = arctan (Im (pathstart (g r)) / Re (pathstart (g r)))" 
            by (subst Im_Ln_eq,auto)
          also have "... = arctan (f (-r))"
            unfolding path_defs by (subst g_f_eq,auto)
          finally show ?thesis .
        qed  
        ultimately show ?thesis by auto
      qed
      finally have "Re (winding_number (g r) 0) = (arctan (f r) - arctan (f (-r)))/(2*pi)" . 
      moreover have "cindex_pathE (g r) 0 = 0"
      proof -
        have "cindex_pathE (g r) 0 = cindex_pathE (poly pp o of_real o (\<lambda>x. 2*r*x - r)) 0"
          unfolding g_def linepath_def comp_def 
          by (auto simp add:algebra_simps)
        also have "... = cindexE 0 1 (f o (\<lambda>x. 2*r*x - r)) "
          unfolding cindex_pathE_def comp_def
          by (simp only:Im_poly_of_real diff_0_right Re_poly_of_real f_def q_def p_def)
        also have "... = cindexE (-r) r f"
          apply (subst cindexE_linear_comp[of "2*r" 0 1 _ "-r",simplified])
          using \<open>r\<ge>1\<close> by auto
        also have "... = 0"
        proof -
          have "jumpF f (at_left x) =0" "jumpF f (at_right x) = 0" when "x\<in>{-r..r}" for x
          proof -
            have "poly p x\<noteq>0" using \<open>proots p={}\<close> unfolding proots_def by auto
            then show "jumpF f (at_left x) =0" "jumpF f (at_right x) = 0"
              unfolding f_def by (auto intro!: jumpF_not_infinity continuous_intros)
          qed
          then show ?thesis unfolding cindexE_def by auto
        qed
        finally show ?thesis .
      qed
      ultimately show "2 * Re (winding_number (g r) 0) + cindex_pathE (g r) 0 
          = (arctan (f r) -  arctan (f (-r))) / pi"   
        unfolding path_defs by (auto simp add:field_simps)
    qed
    with arctan_f_tendsto show ?thesis by (auto dest:tendsto_cong)
  qed
  moreover have ?thesis when "proots p\<noteq>{}"
  proof -
    define max_r where "max_r=Max (proots p)"
    define min_r where "min_r=Min (proots p)"
    have "max_r \<in>proots p" "min_r \<in>proots p" "min_r\<le>max_r" and 
      min_max_bound:"\<forall>p\<in>proots p. p\<in>{min_r..max_r}"
    proof -
      have "p\<noteq>0" 
      proof -
        have "(0::real) \<noteq> 1"
          by simp
        then show ?thesis
          by (metis (full_types) \<open>p \<equiv> map_poly Re pp\<close> assms(2) coeff_0 coeff_map_poly one_complex.simps(1) zero_complex.sel(1))
      qed
      then have "finite (proots p)" by auto
      then show "max_r \<in>proots p" "min_r \<in>proots p"  
        using Min_in Max_in that unfolding max_r_def min_r_def by fast+
      then show "\<forall>p\<in>proots p. p\<in>{min_r..max_r}"
        using Min_le Max_ge \<open>finite (proots p)\<close> unfolding max_r_def min_r_def by auto
      then show "min_r\<le>max_r" using \<open>max_r\<in>proots p\<close> by auto
    qed
    have "\<forall>\<^sub>Fr in at_top. 2 * Re (winding_number (g r) 0) + cindex_pathE (g r) 0
        = (arctan (f r) -  arctan (f (-r))) / pi"
    proof (rule eventually_at_top_linorderI[of "max (norm max_r) (norm min_r) + 1"])  
      fix r assume r_asm:"max (norm max_r) (norm min_r) + 1 \<le> r"
      then have "r\<noteq>0" "min_r>-r" "max_r<r" by auto
      define u where "u=(min_r + r)/(2*r)" 
      define v where "v=(max_r + r)/(2*r)"  
      have uv:"u\<in>{0..1}" "v\<in>{0..1}" "u\<le>v"   
        unfolding u_def v_def using r_asm  \<open>min_r\<le>max_r\<close> 
        by (auto simp add:field_simps)
      define g1 where "g1=subpath 0 u (g r)"
      define g2 where "g2=subpath u v (g r)"
      define g3 where "g3=subpath v 1 (g r)"
      have "path g1" "path g2" "path g3" "valid_path g1" "valid_path g2" "valid_path g3"
        unfolding g1_def g2_def g3_def using uv
        by (auto intro!:path_subpath valid_path_subpath)
      define wc_add where "wc_add = (\<lambda>g. 2*Re (winding_number g 0)  + cindex_pathE g 0)"
      have "wc_add (g r) = wc_add g1 + wc_add g2 + wc_add g3" 
      proof -
        have "winding_number (g r) 0 = winding_number g1 0 + winding_number g2 0 + winding_number g3 0"
          unfolding g1_def g2_def g3_def using \<open>u\<in>{0..1}\<close> \<open>v\<in>{0..1}\<close> not_g_image
          by (subst winding_number_subpath_combine,simp_all)+
        moreover have "cindex_pathE (g r) 0 = cindex_pathE g1 0 + cindex_pathE g2 0 + cindex_pathE g3 0"
          unfolding g1_def g2_def g3_def using \<open>u\<in>{0..1}\<close> \<open>v\<in>{0..1}\<close> \<open>u\<le>v\<close> not_g_image
          by (subst cindex_pathE_subpath_combine,simp_all)+
        ultimately show ?thesis unfolding wc_add_def by auto
      qed
      moreover have "wc_add g2=0"
      proof -
        have "2 * Re (winding_number g2 0) = - cindex_pathE g2 0"
          unfolding g2_def
          apply (rule winding_number_cindex_pathE_aux)
          subgoal using uv by (auto intro:finite_ReZ_segments_subpath)
          subgoal using uv by (auto intro:valid_path_subpath)
          subgoal using Path_Connected.path_image_subpath_subset \<open>\<And>r. path (g r)\<close> not_g_image uv 
            by blast 
          subgoal unfolding subpath_def v_def g_def linepath_def using r_asm \<open>max_r \<in>proots p\<close>
            by (auto simp add:field_simps Re_poly_of_real p_def)
          subgoal unfolding subpath_def u_def g_def linepath_def using r_asm \<open>min_r \<in>proots p\<close>
            by (auto simp add:field_simps Re_poly_of_real p_def)
          done
        then show ?thesis unfolding wc_add_def by auto
      qed
      moreover have "wc_add g1=- arctan (f (-r)) / pi" 
      proof -
        have g1_pq:
          "Re (g1 t) = poly p (min_r*t+r*t-r)"
          "Im (g1 t) = poly q (min_r*t+r*t-r)"
          "Im (g1 t)/Re (g1 t) = (f o (\<lambda>x. (min_r+r)*x - r)) t"
          for t
        proof -
          have "g1 t = poly pp (of_real (min_r*t+r*t-r))"
            using \<open>r\<noteq>0\<close>  unfolding g1_def g_def linepath_def subpath_def u_def p_def 
            by (auto simp add:field_simps)
          then show 
              "Re (g1 t) = poly p (min_r*t+r*t-r)"
              "Im (g1 t) = poly q (min_r*t+r*t-r)"
            unfolding p_def q_def 
            by (simp only:Re_poly_of_real Im_poly_of_real)+
          then show "Im (g1 t)/Re (g1 t) = (f o (\<lambda>x. (min_r+r)*x - r)) t"
            unfolding f_def by (auto simp add:algebra_simps) 
        qed
        have "Re(g1 1)=0"
          using \<open>r\<noteq>0\<close> Re_poly_of_real \<open>min_r\<in>proots p\<close> 
          unfolding g1_def subpath_def u_def g_def linepath_def 
          by (auto simp add:field_simps p_def)
        have "0 \<notin> path_image g1"
          by (metis (full_types) path_image_subpath_subset \<open>\<And>r. path (g r)\<close> 
              atLeastAtMost_iff g1_def le_less not_g_image subsetCE uv(1) zero_le_one)
            
        have wc_add_pos:"wc_add h = - arctan (poly q (- r) / poly p (-r)) / pi" when 
          Re_pos:"\<forall>x\<in>{0..<1}. 0 < (Re \<circ> h) x"
          and hp:"\<forall>t. Re (h t) = c*poly p (min_r*t+r*t-r)"
          and hq:"\<forall>t. Im (h t) = c*poly q (min_r*t+r*t-r)"
          and [simp]:"c\<noteq>0"
          (*and hpq:"\<forall>t. Im (h t)/Re (h t) = (f o (\<lambda>x. (min_r+r)*x - r)) t"*)
          and "Re (h 1) = 0"
          and "valid_path h"
          and h_img:"0 \<notin> path_image h"
          for h c
        proof -
          define f where "f=(\<lambda>t. c*poly q t / (c*poly p t))"
          define farg where "farg= (if 0 < Im (h 1) then pi / 2 else - pi / 2)"
          have "Re (winding_number h 0) = (Im (Ln (pathfinish h)) 
              - Im (Ln (pathstart h))) / (2 * pi)"
            apply (rule Re_winding_number_half_right[of h 0,simplified])
            subgoal using that \<open>Re (h 1) = 0\<close> unfolding path_image_def 
              by (auto simp add:le_less)
            subgoal using \<open>valid_path h\<close> .
            subgoal using h_img .
            done
          also have "... = (farg - arctan (f (-r))) / (2 * pi)"
          proof -
            have "Im (Ln (pathfinish h)) = farg"
              using \<open>Re(h 1)=0\<close> unfolding farg_def path_defs
              apply (subst Im_Ln_eq)
              subgoal using h_img unfolding path_defs by fastforce
              subgoal by simp
              done
            moreover have "Im (Ln (pathstart h)) = arctan (f (-r))"
            proof -
              have "pathstart h \<noteq> 0" 
                using h_img 
                by (metis pathstart_in_path_image)
              then have "Im (Ln (pathstart h)) = arctan (Im (pathstart h) / Re (pathstart h))"
                using Re_pos[rule_format,of 0]
                by (simp add: Im_Ln_eq path_defs)
              also have "... = arctan (f (-r))"
                unfolding f_def path_defs hp[rule_format] hq[rule_format] 
                by simp
              finally show ?thesis .
            qed
            ultimately show ?thesis by auto
          qed
          finally have "Re (winding_number h 0) = (farg - arctan (f (-r))) / (2 * pi)" .
          moreover have "cindex_pathE h 0 = (-farg/pi)"
          proof -
            have "cindex_pathE h 0 = cindexE 0 1 (f \<circ> (\<lambda>x. (min_r + r) * x - r))"
              unfolding cindex_pathE_def using \<open>c\<noteq>0\<close>
              by (auto simp add:hp hq f_def comp_def algebra_simps) 
            also have "... = cindexE (-r) min_r f"
              apply (subst cindexE_linear_comp[where b="-r",simplified])
              using r_asm by auto
            also have "... = - jumpF f (at_left min_r)"
            proof -
              define right where "right = {x. jumpF f (at_right x) \<noteq> 0 \<and> - r \<le> x \<and> x < min_r}"
              define left where "left = {x. jumpF f (at_left x) \<noteq> 0 \<and> - r < x \<and> x \<le> min_r}"
              have *:"jumpF f (at_right x) =0" "jumpF f (at_left x) =0" when "x\<in>{-r..<min_r}" for x
              proof -
                have False when "poly p x =0" 
                proof -
                  have "x\<ge>min_r"
                    using min_max_bound[rule_format,of x] that by auto
                  then show False using \<open>x\<in>{-r..<min_r}\<close> by auto
                qed
                then show "jumpF f (at_right x) =0" "jumpF f (at_left x) =0"
                  unfolding f_def by (auto intro!:jumpF_not_infinity continuous_intros) 
              qed
              then have "right = {}" 
                unfolding right_def by force
              moreover have "left = (if jumpF f (at_left min_r) = 0 then {} else {min_r})"  
                unfolding left_def le_less using * r_asm by force  
              ultimately show ?thesis
                unfolding cindexE_def by (fold left_def right_def,auto)
            qed
            also have "... = (-farg/pi)"
            proof -
              have p_pos:"c*poly p x > 0" when "x \<in> {- r<..<min_r}" for x
              proof -
                define hh where "hh=(\<lambda>t. min_r*t+r*t-r)"
                have "(x+r)/(min_r+r) \<in> {0..<1}"
                  using that r_asm by (auto simp add:field_simps)
                then have "0 < c*poly p (hh ((x+r)/(min_r+r)))"
                  apply (drule_tac Re_pos[rule_format])
                  unfolding comp_def hp[rule_format]  hq[rule_format] hh_def .
                moreover have "hh ((x+r)/(min_r+r)) = x"
                  unfolding hh_def using \<open>min_r>-r\<close> 
                  apply (auto simp add:divide_simps)
                  by (auto simp add:algebra_simps)
                ultimately show ?thesis by simp
              qed
              
              have "c*poly q min_r \<noteq>0"
                using no_real_zero \<open>c\<noteq>0\<close>
                by (metis Im_complex_of_real UNIV_I \<open>min_r \<in> proots p\<close> cpoly_of_decompose 
                    mult_eq_0_iff p_def poly_cpoly_of_real_iff proots_within_iff q_def)
                
              moreover have ?thesis when "c*poly q min_r > 0"
              proof -
                have "0 < Im (h 1)" unfolding hq[rule_format] hp[rule_format] using that by auto
                moreover have "jumpF f (at_left min_r) = 1/2"
                proof -
                  have "((\<lambda>t. c*poly p t) has_sgnx 1) (at_left min_r)"
                    unfolding has_sgnx_def
                    apply (rule eventually_at_leftI[of "-r"])
                    using p_pos \<open>min_r>-r\<close> by auto
                  then have "filterlim f at_top (at_left min_r)" 
                    unfolding f_def
                    apply (subst filterlim_divide_at_bot_at_top_iff[of _ "c*poly q min_r"])
                    using that \<open>min_r\<in>proots p\<close> by (auto intro!:tendsto_eq_intros)
                  then show ?thesis unfolding jumpF_def by auto
                qed
                ultimately show ?thesis unfolding farg_def by auto
              qed
              moreover have ?thesis when "c*poly q min_r < 0"
              proof -
                have "0 > Im (h 1)" unfolding hq[rule_format] hp[rule_format] using that by auto
                moreover have "jumpF f (at_left min_r) = - 1/2"
                proof -
                  have "((\<lambda>t. c*poly p t) has_sgnx 1) (at_left min_r)"
                    unfolding has_sgnx_def
                    apply (rule eventually_at_leftI[of "-r"])
                    using p_pos \<open>min_r>-r\<close> by auto
                  then have "filterlim f at_bot (at_left min_r)" 
                    unfolding f_def
                    apply (subst filterlim_divide_at_bot_at_top_iff[of _ "c*poly q min_r"])
                    using that \<open>min_r\<in>proots p\<close> by (auto intro!:tendsto_eq_intros)
                  then show ?thesis unfolding jumpF_def by auto
                qed
                ultimately show ?thesis unfolding farg_def by auto
              qed 
              ultimately show ?thesis by linarith
            qed
            finally show ?thesis .
          qed
          ultimately show ?thesis unfolding wc_add_def f_def by (auto simp add:field_simps)  
        qed
        
        have "\<forall>x\<in>{0..<1}. (Re \<circ> g1) x \<noteq> 0" 
        proof (rule ccontr)
          assume "\<not> (\<forall>x\<in>{0..<1}. (Re \<circ> g1) x \<noteq> 0)"
          then obtain t where t_def:"Re (g1 t) =0" "t\<in>{0..<1}"
            unfolding path_image_def by fastforce
          define m where "m=min_r*t+r*t-r"
          have "poly p m=0"
          proof -
            have "Re (g1 t) = Re (poly pp (of_real m))"
              unfolding m_def g1_def g_def linepath_def subpath_def u_def using \<open>r\<noteq>0\<close>
              by (auto simp add:field_simps)
            then show ?thesis using t_def unfolding Re_poly_of_real p_def by auto 
          qed
          moreover have "m<min_r"
          proof -
            have "min_r+r>0" using r_asm by simp
            then have "(min_r + r)*(t-1)<0" using \<open>t\<in>{0..<1}\<close> 
              by (simp add: mult_pos_neg)  
            then show ?thesis unfolding m_def by (auto simp add:algebra_simps)
          qed
          ultimately show False using min_max_bound unfolding proots_def by auto
        qed
        then have "(\<forall>x\<in>{0..<1}. 0 < (Re \<circ> g1) x) \<or> (\<forall>x\<in>{0..<1}. (Re \<circ> g1) x < 0)"
          apply (elim continuous_on_neq_split)
          using \<open>path g1\<close> unfolding path_def 
          by (auto intro!:continuous_intros elim:continuous_on_subset)
        moreover have ?thesis when "\<forall>x\<in>{0..<1}. (Re \<circ> g1) x < 0"
        proof -
          have "wc_add (uminus o g1) = - arctan (f (- r)) / pi"
            unfolding f_def
            apply (rule wc_add_pos[of _ "-1"])
            using g1_pq that \<open>min_r \<in>proots p\<close> \<open>valid_path g1\<close> \<open>0 \<notin> path_image g1\<close>  
            by (auto simp add:path_image_compose)
          moreover have "wc_add (uminus \<circ> g1) = wc_add g1"
            unfolding wc_add_def cindex_pathE_def
            apply (subst winding_number_uminus_comp)
            using \<open>valid_path g1\<close> \<open>0 \<notin> path_image g1\<close> by auto   
          ultimately show ?thesis by auto
        qed
        moreover have ?thesis when "\<forall>x\<in>{0..<1}. (Re \<circ> g1) x > 0"
          unfolding f_def
          apply (rule wc_add_pos[of _ "1"])
          using g1_pq that \<open>min_r \<in>proots p\<close> \<open>valid_path g1\<close> \<open>0 \<notin> path_image g1\<close>  
          by (auto simp add:path_image_compose)
        ultimately show ?thesis by blast
      qed
      moreover have "wc_add g3 = arctan (f r) / pi" 
      proof -
        have g3_pq:
          "Re (g3 t) = poly p ((r-max_r)*t + max_r)"
          "Im (g3 t) = poly q ((r-max_r)*t + max_r)"
          "Im (g3 t)/Re (g3 t) = (f o (\<lambda>x. (r-max_r)*x + max_r)) t"
          for t
        proof -
          have "g3 t = poly pp (of_real ((r-max_r)*t + max_r))"
            using \<open>r\<noteq>0\<close> \<open>max_r<r\<close>  unfolding g3_def g_def linepath_def subpath_def v_def p_def 
            by (auto simp add:algebra_simps)
          then show 
              "Re (g3 t) = poly p ((r-max_r)*t + max_r)"
              "Im (g3 t) = poly q ((r-max_r)*t + max_r)"
            unfolding p_def q_def 
            by (simp only:Re_poly_of_real Im_poly_of_real)+
          then show "Im (g3 t)/Re (g3 t) = (f o (\<lambda>x. (r-max_r)*x + max_r)) t"
            unfolding f_def by (auto simp add:algebra_simps) 
        qed
        have "Re(g3 0)=0"
          using \<open>r\<noteq>0\<close> Re_poly_of_real \<open>max_r\<in>proots p\<close> 
          unfolding g3_def subpath_def v_def g_def linepath_def 
          by (auto simp add:field_simps p_def)
        have "0 \<notin> path_image g3"
        proof -
          have "(1::real) \<in> {0..1}"
            by auto
          then show ?thesis
            using Path_Connected.path_image_subpath_subset \<open>\<And>r. path (g r)\<close> g3_def not_g_image uv(2) by blast
        qed
            
        have wc_add_pos:"wc_add h = arctan (poly q r / poly p r) / pi" when 
          Re_pos:"\<forall>x\<in>{0<..1}. 0 < (Re \<circ> h) x"
          and hp:"\<forall>t. Re (h t) = c*poly p ((r-max_r)*t + max_r)"
          and hq:"\<forall>t. Im (h t) = c*poly q ((r-max_r)*t + max_r)"
          and [simp]:"c\<noteq>0"
          (*and hpq:"\<forall>t. Im (h t)/Re (h t) = (f o (\<lambda>x. (min_r+r)*x - r)) t"*)
          and "Re (h 0) = 0"
          and "valid_path h"
          and h_img:"0 \<notin> path_image h"
          for h c
        proof -
          define f where "f=(\<lambda>t. c*poly q t / (c*poly p t))"
          define farg where "farg= (if 0 < Im (h 0) then pi / 2 else - pi / 2)"
          have "Re (winding_number h 0) = (Im (Ln (pathfinish h)) 
              - Im (Ln (pathstart h))) / (2 * pi)"
            apply (rule Re_winding_number_half_right[of h 0,simplified])
            subgoal using that \<open>Re (h 0) = 0\<close> unfolding path_image_def 
              by (auto simp add:le_less)
            subgoal using \<open>valid_path h\<close> .
            subgoal using h_img .
            done
          also have "... = (arctan (f r) - farg) / (2 * pi)"
          proof -
            have "Im (Ln (pathstart h)) = farg"
              using \<open>Re(h 0)=0\<close> unfolding farg_def path_defs
              apply (subst Im_Ln_eq)
              subgoal using h_img unfolding path_defs by fastforce
              subgoal by simp
              done
            moreover have "Im (Ln (pathfinish h)) = arctan (f r)"
            proof -
              have "pathfinish h \<noteq> 0" 
                using h_img 
                by (metis pathfinish_in_path_image)
              then have "Im (Ln (pathfinish h)) = arctan (Im (pathfinish h) / Re (pathfinish h))"
                using Re_pos[rule_format,of 1]
                by (simp add: Im_Ln_eq path_defs)
              also have "... = arctan (f r)"
                unfolding f_def path_defs hp[rule_format] hq[rule_format] 
                by simp
              finally show ?thesis .
            qed
            ultimately show ?thesis by auto
          qed
          finally have "Re (winding_number h 0) = (arctan (f r) - farg) / (2 * pi)" .
          moreover have "cindex_pathE h 0 = farg/pi"
          proof -
            have "cindex_pathE h 0 = cindexE 0 1 (f \<circ> (\<lambda>x. (r-max_r)*x + max_r))"
              unfolding cindex_pathE_def using \<open>c\<noteq>0\<close>
              by (auto simp add:hp hq f_def comp_def algebra_simps) 
            also have "... = cindexE max_r r f"
              apply (subst cindexE_linear_comp)
              using r_asm by auto
            also have "... = jumpF f (at_right max_r)"
            proof -
              define right where "right = {x. jumpF f (at_right x) \<noteq> 0 \<and> max_r \<le> x \<and> x < r}"
              define left where "left = {x. jumpF f (at_left x) \<noteq> 0 \<and> max_r < x \<and> x \<le> r}"
              have *:"jumpF f (at_right x) =0" "jumpF f (at_left x) =0" when "x\<in>{max_r<..r}" for x
              proof -
                have False when "poly p x =0" 
                proof -
                  have "x\<le>max_r"
                    using min_max_bound[rule_format,of x] that by auto
                  then show False using \<open>x\<in>{max_r<..r}\<close> by auto
                qed
                then show "jumpF f (at_right x) =0" "jumpF f (at_left x) =0"
                  unfolding f_def by (auto intro!:jumpF_not_infinity continuous_intros) 
              qed
              then have "left = {}" 
                unfolding left_def by force
              moreover have "right = (if jumpF f (at_right max_r) = 0 then {} else {max_r})"  
                unfolding right_def le_less using * r_asm by force  
              ultimately show ?thesis
                unfolding cindexE_def by (fold left_def right_def,auto)
            qed
            also have "... = farg/pi"
            proof -
              have p_pos:"c*poly p x > 0" when "x \<in> {max_r<..<r}" for x
              proof -
                define hh where "hh=(\<lambda>t. (r-max_r)*t + max_r)"
                have "(x-max_r)/(r-max_r) \<in> {0<..1}"
                  using that r_asm by (auto simp add:field_simps)
                then have "0 < c*poly p (hh ((x-max_r)/(r-max_r)))"
                  apply (drule_tac Re_pos[rule_format]) 
                  unfolding comp_def hp[rule_format]  hq[rule_format] hh_def .
                moreover have "hh ((x-max_r)/(r-max_r)) = x"
                  unfolding hh_def using \<open>max_r<r\<close> 
                  by (auto simp add:divide_simps)
                ultimately show ?thesis by simp
              qed
              
              have "c*poly q max_r \<noteq>0"
                using no_real_zero \<open>c\<noteq>0\<close>
                by (metis Im_complex_of_real UNIV_I \<open>max_r \<in> proots p\<close> cpoly_of_decompose 
                    mult_eq_0_iff p_def poly_cpoly_of_real_iff proots_within_iff q_def)
                
              moreover have ?thesis when "c*poly q max_r > 0"
              proof -
                have "0 < Im (h 0)" unfolding hq[rule_format] hp[rule_format] using that by auto
                moreover have "jumpF f (at_right max_r) = 1/2"
                proof -
                  have "((\<lambda>t. c*poly p t) has_sgnx 1) (at_right max_r)"
                    unfolding has_sgnx_def 
                    apply (rule eventually_at_rightI[of _ "r"])
                    using p_pos \<open>max_r<r\<close> by auto
                  then have "filterlim f at_top (at_right max_r)" 
                    unfolding f_def
                    apply (subst filterlim_divide_at_bot_at_top_iff[of _ "c*poly q max_r"])
                    using that \<open>max_r\<in>proots p\<close> by (auto intro!:tendsto_eq_intros)
                  then show ?thesis unfolding jumpF_def by auto
                qed
                ultimately show ?thesis unfolding farg_def by auto
              qed
              moreover have ?thesis when "c*poly q max_r < 0"
              proof -
                have "0 > Im (h 0)" unfolding hq[rule_format] hp[rule_format] using that by auto
                moreover have "jumpF f (at_right max_r) = - 1/2"
                proof -
                  have "((\<lambda>t. c*poly p t) has_sgnx 1) (at_right max_r)"
                    unfolding has_sgnx_def
                    apply (rule eventually_at_rightI[of _ "r"])
                    using p_pos \<open>max_r<r\<close> by auto
                  then have "filterlim f at_bot (at_right max_r)" 
                    unfolding f_def
                    apply (subst filterlim_divide_at_bot_at_top_iff[of _ "c*poly q max_r"])
                    using that \<open>max_r\<in>proots p\<close> by (auto intro!:tendsto_eq_intros)
                  then show ?thesis unfolding jumpF_def by auto
                qed
                ultimately show ?thesis unfolding farg_def by auto
              qed 
              ultimately show ?thesis by linarith
            qed
            finally show ?thesis .
          qed
          ultimately show ?thesis unfolding wc_add_def f_def by (auto simp add:field_simps)  
        qed
        
        have "\<forall>x\<in>{0<..1}. (Re \<circ> g3) x \<noteq> 0" 
        proof (rule ccontr)
          assume "\<not> (\<forall>x\<in>{0<..1}. (Re \<circ> g3) x \<noteq> 0)"
          then obtain t where t_def:"Re (g3 t) =0" "t\<in>{0<..1}"
            unfolding path_image_def by fastforce
          define m where "m=(r-max_r)*t + max_r"
          have "poly p m=0"
          proof -
            have "Re (g3 t) = Re (poly pp (of_real m))"
              unfolding m_def g3_def g_def linepath_def subpath_def v_def using \<open>r\<noteq>0\<close>
              by (auto simp add:algebra_simps)
            then show ?thesis using t_def unfolding Re_poly_of_real p_def by auto 
          qed
          moreover have "m>max_r"
          proof -
            have "r-max_r>0" using r_asm by simp
            then have "(r - max_r)*t>0" using \<open>t\<in>{0<..1}\<close> 
              by (simp add: mult_pos_neg)  
            then show ?thesis unfolding m_def by (auto simp add:algebra_simps)
          qed
          ultimately show False using min_max_bound unfolding proots_def by auto
        qed
        then have "(\<forall>x\<in>{0<..1}. 0 < (Re \<circ> g3) x) \<or> (\<forall>x\<in>{0<..1}. (Re \<circ> g3) x < 0)"
          apply (elim continuous_on_neq_split)
          using \<open>path g3\<close> unfolding path_def 
          by (auto intro!:continuous_intros elim:continuous_on_subset)
        moreover have ?thesis when "\<forall>x\<in>{0<..1}. (Re \<circ> g3) x < 0"
        proof -
          have "wc_add (uminus o g3) = arctan (f r) / pi"
            unfolding f_def
            apply (rule wc_add_pos[of _ "-1"])
            using g3_pq that \<open>max_r \<in>proots p\<close> \<open>valid_path g3\<close> \<open>0 \<notin> path_image g3\<close>  
            by (auto simp add:path_image_compose)
          moreover have "wc_add (uminus \<circ> g3) = wc_add g3"
            unfolding wc_add_def cindex_pathE_def
            apply (subst winding_number_uminus_comp)
            using \<open>valid_path g3\<close> \<open>0 \<notin> path_image g3\<close> by auto   
          ultimately show ?thesis by auto
        qed
        moreover have ?thesis when "\<forall>x\<in>{0<..1}. (Re \<circ> g3) x > 0"
          unfolding f_def
          apply (rule wc_add_pos[of _ "1"])
          using g3_pq that \<open>max_r \<in>proots p\<close> \<open>valid_path g3\<close> \<open>0 \<notin> path_image g3\<close>  
          by (auto simp add:path_image_compose)
        ultimately show ?thesis by blast
      qed  
      ultimately have "wc_add (g r) = (arctan (f r) - arctan (f (-r))) / pi " 
        by (auto simp add:field_simps)
      then show "2 * Re (winding_number (g r) 0) + cindex_pathE (g r) 0 
          = (arctan (f r) - arctan (f (- r))) / pi" 
        unfolding wc_add_def .
    qed
    with arctan_f_tendsto show ?thesis by (auto dest:tendsto_cong)
  qed
  ultimately show ?thesis by auto
qed
  
lemma proots_upper_cindex_eq:
  assumes "lead_coeff p=1" and no_real_roots:"\<forall>x\<in>proots p. Im x\<noteq>0" 
  shows "proots_upper p =
             (degree p - cindex_poly_ubd (map_poly Im p) (map_poly Re p)) /2"  
proof (cases "degree p = 0")
  case True
  then obtain c where "p=[:c:]" using degree_eq_zeroE by blast
  then have p_def:"p=[:1:]" using \<open>lead_coeff p=1\<close> by simp
  have "proots_count p {x. Im x>0} = 0" unfolding p_def proots_count_def by auto  
  moreover have "cindex_poly_ubd (map_poly Im p) (map_poly Re p) = 0"
    apply (subst cindex_poly_ubd_code)
    unfolding p_def 
    by (auto simp add:map_poly_pCons changes_R_smods_def changes_poly_neg_inf_def 
        changes_poly_pos_inf_def)  
  ultimately show ?thesis using True unfolding proots_upper_def by auto
next
  case False
  then have "degree p>0" "p\<noteq>0" by auto
  define w1 where "w1=(\<lambda>r. Re (winding_number (poly p \<circ> 
              (\<lambda>x. complex_of_real (linepath (- r) (of_real r) x))) 0))"  
  define w2 where "w2=(\<lambda>r. Re (winding_number (poly p \<circ> part_circlepath 0 r 0 pi) 0))"
  define cp where "cp=(\<lambda>r. cindex_pathE (poly p \<circ> (\<lambda>x. 
      of_real (linepath (- r) (of_real r) x))) 0)"
  define ci where "ci=(\<lambda>r. cindexE (-r) r (\<lambda>x. poly (map_poly Im p) x/poly (map_poly Re p) x))"
  define cubd where "cubd =cindex_poly_ubd (map_poly Im p) (map_poly Re p)"
  obtain R where "proots p \<subseteq> ball 0 R" and "R>0"
    using \<open>p\<noteq>0\<close> finite_ball_include[of "proots p" 0] by auto
  have "((\<lambda>r. w1 r  +w2 r+ cp r / 2 -ci r/2)
       \<longlongrightarrow> real (degree p) / 2 - of_int cubd / 2) at_top"  
  proof -
    have t1:"((\<lambda>r. 2 * w1 r + cp r) \<longlongrightarrow> 0) at_top"
      using Re_winding_number_poly_linepth[OF assms] unfolding w1_def cp_def by auto
    have t2:"(w2 \<longlongrightarrow> real (degree p) / 2) at_top"
      using Re_winding_number_poly_part_circlepath[OF \<open>degree p>0\<close>,of 0] unfolding w2_def by auto
    have t3:"(ci \<longlongrightarrow> of_int cubd) at_top"
      apply (rule Lim_eventually)
      using cindex_poly_ubd_eventually[of "map_poly Im p" "map_poly Re p"] 
      unfolding ci_def cubd_def by auto
    from tendsto_add[OF tendsto_add[OF tendsto_mult_left[OF t3,of "-1/2",simplified] 
         tendsto_mult_left[OF t1,of "1/2",simplified]]
         t2]
    show ?thesis by (simp add:algebra_simps)
  qed
  moreover have "\<forall>\<^sub>F r in at_top. w1 r  +w2 r+ cp r / 2 -ci r/2 = proots_count p {x. Im x>0}" 
  proof (rule eventually_at_top_linorderI[of R])
    fix r assume "r\<ge>R"
    then have r_ball:"proots p \<subseteq> ball 0 r" and "r>0"
      using \<open>R>0\<close> \<open>proots p \<subseteq> ball 0 R\<close> by auto
    define ll where "ll=linepath (- complex_of_real r) r"
    define rr where "rr=part_circlepath 0 r 0 pi"
    define lr where "lr = ll +++ rr"
    have img_ll:"path_image ll \<subseteq> - proots p" and img_rr: "path_image rr \<subseteq> - proots p" 
      subgoal unfolding ll_def using \<open>0 < r\<close> closed_segment_degen_complex(2) no_real_roots by auto
      subgoal unfolding rr_def using in_path_image_part_circlepath \<open>0 < r\<close> r_ball by fastforce 
      done
    have [simp]:"valid_path (poly p o ll)" "valid_path (poly p o rr)"
        "valid_path ll" "valid_path rr" 
        "pathfinish rr=pathstart ll" "pathfinish ll = pathstart rr"
    proof -
      show "valid_path (poly p o ll)" "valid_path (poly p o rr)"
        unfolding ll_def rr_def by (auto intro:valid_path_compose_holomorphic)
      then show "valid_path ll" "valid_path rr" unfolding ll_def rr_def by auto
      show "pathfinish rr=pathstart ll" "pathfinish ll = pathstart rr"
        unfolding ll_def rr_def by auto
    qed
    have "proots_count p {x. Im x>0} = (\<Sum>x\<in>proots p. winding_number lr x * of_nat (order x p))"
    unfolding proots_count_def of_nat_sum
    proof (rule sum.mono_neutral_cong_left)
      show "finite (proots p)" "proots_within p {x. 0 < Im x} \<subseteq> proots p"
        using \<open>p\<noteq>0\<close> by auto
    next
      have "winding_number lr x=0" when "x\<in>proots p - proots_within p {x. 0 < Im x}" for x
      unfolding lr_def ll_def rr_def
      proof (eval_winding,simp_all)
        show *:"x \<notin> closed_segment (- complex_of_real r) (complex_of_real r)"
          using img_ll that unfolding ll_def by auto
        show "x \<notin> path_image (part_circlepath 0 r 0 pi)"
          using img_rr that unfolding rr_def by auto
        have xr_facts:"0 > Im x" "-r<Re x" "Re x<r" "cmod x<r"
        proof -
          have "Im x\<le>0" using that by auto
          moreover have "Im x\<noteq>0" using no_real_roots that by blast
          ultimately show "0 > Im x" by auto
        next
          show "cmod x<r" using that r_ball by auto
          then have "\<bar>Re x\<bar> < r"
            using abs_Re_le_cmod[of x] by argo  
          then show "-r<Re x" "Re x<r"  by linarith+
        qed
        then have "cindex_pathE ll x = 1"
          using \<open>r>0\<close> unfolding cindex_pathE_linepath[OF *] ll_def 
          by (auto simp add: mult_pos_neg)
        moreover have "cindex_pathE rr x=-1"
          unfolding rr_def using r_ball that
          by (auto intro!: cindex_pathE_half_circlepath)
        ultimately show "-cindex_pathE (linepath (- of_real r) (of_real r)) x =
            cindex_pathE (part_circlepath 0 r 0 pi) x"
          unfolding ll_def rr_def by auto
      qed
      then show "\<forall>i\<in>proots p - proots_within p {x. 0 < Im x}. 
          winding_number lr i * of_nat (order i p) = 0"
        by auto
    next
      fix x assume x_asm:"x \<in> proots_within p {x. 0 < Im x}"
      have "winding_number lr x=1" unfolding lr_def ll_def rr_def
      proof (eval_winding,simp_all) 
        show *:"x \<notin> closed_segment (- complex_of_real r) (complex_of_real r)"
          using img_ll x_asm unfolding ll_def by auto
        show "x \<notin> path_image (part_circlepath 0 r 0 pi)"
          using img_rr x_asm unfolding rr_def by auto
        have xr_facts:"0 < Im x" "-r<Re x" "Re x<r" "cmod x<r"
        proof -
          show "0 < Im x" using x_asm by auto
        next
          show "cmod x<r" using x_asm r_ball by auto
          then have "\<bar>Re x\<bar> < r"
            using abs_Re_le_cmod[of x] by argo  
          then show "-r<Re x" "Re x<r"  by linarith+
        qed
        then have "cindex_pathE ll x = -1"
          using \<open>r>0\<close> unfolding cindex_pathE_linepath[OF *] ll_def 
          by (auto simp add: mult_less_0_iff)
        moreover have "cindex_pathE rr x=-1"
          unfolding rr_def using r_ball x_asm
          by (auto intro!: cindex_pathE_half_circlepath)
        ultimately show "- of_real (cindex_pathE (linepath (- of_real r) (of_real r)) x) -
            of_real (cindex_pathE (part_circlepath 0 r 0 pi) x) = 2"  
          unfolding ll_def rr_def by auto 
      qed
      then show "of_nat (order x p) = winding_number lr x * of_nat (order x p)" by auto
    qed
    also have "... = 1/(2*pi*\<i>) * contour_integral lr (\<lambda>x. deriv (poly p) x / poly p x)"
      apply (subst argument_principle_poly[of p lr])
      using \<open>p\<noteq>0\<close> img_ll img_rr unfolding lr_def ll_def rr_def
      by (auto simp add:path_image_join)
    also have "... = winding_number (poly p \<circ> lr) 0"  
      apply (subst winding_number_comp[of UNIV "poly p" lr 0])
      using \<open>p\<noteq>0\<close> img_ll img_rr unfolding lr_def ll_def rr_def
      by (auto simp add:path_image_join path_image_compose)
    also have "... = Re (winding_number (poly p \<circ> lr) 0)" 
    proof -
      have "winding_number (poly p \<circ> lr) 0 \<in> Ints" 
        apply (rule integer_winding_number)
        using \<open>p\<noteq>0\<close> img_ll img_rr unfolding lr_def 
        by (auto simp add:path_image_join path_image_compose path_compose_join 
            pathstart_compose pathfinish_compose valid_path_imp_path)
      then show ?thesis by (simp add: complex_equality complex_is_Int_iff)
    qed
    also have "... =  Re (winding_number (poly p \<circ> ll) 0) + Re (winding_number (poly p \<circ> rr) 0)"
      unfolding lr_def path_compose_join using img_ll img_rr
      apply (subst winding_number_join)
      by (auto simp add:valid_path_imp_path path_image_compose pathstart_compose pathfinish_compose)
    also have "... = w1 r  +w2 r"
      unfolding w1_def w2_def ll_def rr_def of_real_linepath by auto
    finally have "of_nat (proots_count p {x. 0 < Im x}) = complex_of_real (w1 r + w2 r)" .
    then have "proots_count p {x. 0 < Im x} = w1 r + w2 r" 
      using of_real_eq_iff by fastforce
    moreover have "cp r = ci r"
    proof -
      define f where "f=(\<lambda>x. Im (poly p (of_real x)) / Re (poly p x))"
      have "cp r = cindex_pathE (poly p \<circ> (\<lambda>x. 2*r*x - r)) 0"
        unfolding cp_def linepath_def by (auto simp add:algebra_simps)
      also have "... = cindexE 0 1 (f o (\<lambda>x. 2*r*x - r))"
        unfolding cp_def ci_def cindex_pathE_def f_def comp_def by auto
      also have "... = cindexE (-r) r f"
        apply (subst cindexE_linear_comp[of "2*r" 0 1 f "-r",simplified])
        using \<open>r>0\<close> by auto
      also have "... = ci r"
        unfolding ci_def f_def Im_poly_of_real Re_poly_of_real by simp
      finally show ?thesis .
    qed
    ultimately show "w1 r + w2 r + cp r / 2 - ci r / 2 = real (proots_count p {x. 0 < Im x})"
      by auto
  qed
  ultimately have "((\<lambda>r::real. real (proots_count p {x. 0 < Im x})) 
      \<longlongrightarrow> real (degree p) / 2 - of_int cubd / 2) at_top"
    by (auto dest: tendsto_cong)
  then show ?thesis
    apply (subst (asm) tendsto_const_iff)
    unfolding cubd_def proots_upper_def by auto
qed
    
lemma proots_upper_code1[code]:
  "proots_upper p = (if p \<noteq> 0 then
       (let pp=smult (inverse (lead_coeff p)) p;
            pI=map_poly Im pp;
            pR=map_poly Re pp;
            g = gcd pI pR
        in
          if changes_R_smods g (pderiv g) = 0 
          then 
            (degree p - changes_R_smods pR pI) div 2 
          else 
            Code.abort (STR ''proots_upper fails when there is a root on the border.'') 
              (\<lambda>_. proots_upper p) 
      )
    else 
      Code.abort (STR ''proots_upper fails when p=0.'') (\<lambda>_. proots_upper p))"
proof -
  define pp where "pp = smult (inverse (lead_coeff p)) p"
  define pI where "pI = map_poly Im pp"
  define pR where "pR=map_poly Re pp"
  define g where  "g = gcd pI pR"
  have ?thesis when "p=0"
    using that by auto
  moreover have ?thesis when "p\<noteq>0" "changes_R_smods g (pderiv g) \<noteq> 0"
    using that unfolding Let_def by (fold pp_def pI_def pR_def g_def,auto)
  moreover have ?thesis when "p\<noteq>0" 
    and changes_0:"changes_R_smods g (pderiv g) = 0"
  proof -
    have "lead_coeff p\<noteq>0" using \<open>p\<noteq>0\<close> by simp
    
    define dc where "dc=int (degree pp) - cindex_poly_ubd pI pR"
    have "(proots_upper pp) = of_int dc / 2" unfolding dc_def
    proof (rule proots_upper_cindex_eq[of pp,folded pI_def pR_def])
      show "lead_coeff pp = 1"
        using \<open>lead_coeff p\<noteq>0\<close> unfolding pp_def lead_coeff_smult by auto
    next
      have "card {x. poly g x = 0} = 0"
        using changes_0 by (subst (asm) sturm_R[symmetric],auto)
      moreover have "g\<noteq>0" 
      proof (rule ccontr)
        assume "\<not> g \<noteq> 0"
        then have "pI =0" "pR = 0" unfolding g_def by auto
        then have "pp=0" unfolding pI_def pR_def
          by (metis cpoly_of_decompose map_poly_0)
        then have "p=0" unfolding pp_def by fastforce
        then show False using \<open>p\<noteq>0\<close> by auto
      qed
      then have "finite (proots g)" by auto
      ultimately have "proots g = {}"
        unfolding card_eq_0_iff proots_def by auto
      show "\<forall>x\<in>proots pp. Im x \<noteq> 0" 
      proof (rule ccontr)
        assume "\<not> (\<forall>x\<in>proots pp. Im x \<noteq> 0)"
        then obtain x where "x\<in>proots pp" and "Im x=0" by auto
        then obtain t where "x = of_real t"
          by (simp add: complex_Re_Im_cancel_iff)
        then have "poly pp (of_real t) = 0"
          using \<open>x\<in>proots pp\<close> by auto
        then have "Re (poly pp (of_real t)) = 0" "Im (poly pp (of_real t)) = 0"
          by auto
        then have "poly pR t = 0" "poly pI t = 0"
          unfolding pR_def pI_def Re_poly_of_real Im_poly_of_real by auto
        then have "poly g t=0"
          unfolding g_def poly_gcd_iff by auto
        then show False using \<open>proots g = {}\<close> by auto
      qed
    qed
    also have "... = of_int dc / (of_int 2)"  
      by simp
    also have "... = real_of_int (dc div 2)"
      apply (subst real_of_int_div[symmetric])
       apply (metis Ints_of_int \<open>(proots_upper pp) = real_of_int dc / 2\<close> 
          fraction_not_in_ints of_int_numeral rel_simps(76)) 
      by simp
    finally have "(proots_upper pp) = real_of_int (dc div 2)" .
    then have "(proots_upper pp) = dc div 2" by simp
    then have "proots_upper pp = (int (degree pp) - changes_R_smods pR pI) div 2" 
      unfolding dc_def cindex_poly_ubd_code proots_upper_def by auto
    then have "proots_upper p = (int (degree p) - changes_R_smods pR pI) div 2"   
      unfolding pp_def proots_upper_def using \<open>lead_coeff p \<noteq>0\<close>
      by (simp add:proots_count_smult)        
    then show ?thesis unfolding Let_def
      apply (fold pp_def pI_def pR_def g_def)
      using that by auto
  qed
  ultimately show ?thesis by fast
qed
  
lemma proots_half_code1[code]:
  "proots_half p a b = (if a\<noteq>b then 
                        if p\<noteq>0 then proots_upper (p \<circ>\<^sub>p [:a, b - a:]) 
                        else Code.abort (STR ''proots_half fails when p=0.'') 
                          (\<lambda>_. proots_half p a b) 
                        else 0)"
proof -
  have ?thesis when "a=b"
    using proots_half_empty that by auto
  moreover have ?thesis when "a\<noteq>b" "p=0"
    using that by auto
  moreover have ?thesis when "a\<noteq>b" "p\<noteq>0"
    using proots_half_proots_upper[OF that] that by auto
  ultimately show ?thesis by auto
qed
  
end
  

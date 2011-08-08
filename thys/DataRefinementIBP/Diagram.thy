header {*  Predicate Transformers Semantics of Invariant Diagrams  *}

theory Diagram
imports Hoare
begin

text {*
This theory introduces the concept of a transition diagram and proves
a number of Hoare total corectness rules for these diagrams. As before
the diagrams are introduced using their predicate transformer semantics.

A transition diagram $D$ is a function from pairs of indexes to predicate
transformers: $D:I\times I \to (\mathit{State}\ \mathit{set}\to \mathit{State}\ \mathit{set})$, or more
general $D:I\times I \to \mathit{Ptran}$, where $\mathit{Ptran}$ is a complete lattice. The elements
of $I$ are called situations and intuitively a diagram is executed starting
in a situation $i\in I$ by choosing a transition $D (i,j)$ which is enabled
and continuing similarly from $j$ if there are enabled trasitions. The 
execution of a diagram stops when there are no more transitions enabled or
when it fails.

The semantics of a transition diagram is an indexed predicate transformer 
($I\to \mathit{State}\ \mathit{set}$).
If $Q:I\to \mathit{State}\ \mathit{set}$ is an indexed predicate, then $p = \mathit{pt}\ D\ Q\ i$ is a
weakest predicate such that if the executution of $D$ starts in a state
$s\in p$ from situation $i$, then it terminates, and if it terminates
in situation $j$ and state $s'$, then $s'\in Q \  j$.

We introduce first the indexed predicate transformer $\mathit{step}\ D$ of executing
one step of diagram $D$. The predicate $step\ D\ Q\ i$ is true for those
states $s$ from which the execution of one step of $D$ starting in situation 
$i$ ends in one of the situations $j$ such that $Q \, j$ is true.

*}

definition
  "step D Q i = (INF j . D (i, j) (Q j))"

definition
  "dmono D = (\<forall> ij . mono (D ij))"

lemma dmono_mono [simp]: "dmono D \<Longrightarrow> mono (D ij)"
  by (simp add: dmono_def)

theorem mono_step [simp]:
  "dmono D \<Longrightarrow> mono (step D)"
  apply (simp add: dmono_def mono_def le_fun_def step_def Inf_fun_def)
  apply auto
  apply (rule le_INFI)
  apply auto
  apply (rule_tac y = "D(xa, j) (x j)" in order_trans)
  apply auto
  apply (rule INF_leI)
  by auto

text {*
The indexed predicate transformer of a transition diagram is defined as the least
fixpoint of the unfolding of the execution of the diagram. The indexed predicate
transformer $dgr\ D\ U$ is the choice between executing one step of $D$ follwed by
$U$ ($(\mathit{step}\ D)\circ U$) or skip if no transion of $D$ is enabled 
($\mathit{assume}\ \neg \mathit{grd} (\mathit{step}\ D)$).
*}

definition
  "dgr D U = ((step D) o U) \<sqinter> (assume (-(grd (step D))))"

theorem mono_mono_dgr [simp]: "dmono D \<Longrightarrow> mono_mono (dgr D)"
  apply (simp add: mono_mono_def mono_def)
  apply safe
  apply (simp_all add: dgr_def)
  apply (simp_all add: le_fun_def inf_fun_def)
  apply safe
  apply (rule_tac y = "(step D (x xa) xb)" in order_trans)
  apply simp_all
  apply (case_tac "mono (step D)")
  apply (simp add: mono_def)
  apply (simp add: le_fun_def)
  apply simp
  apply (rule_tac y = "(step D (f x) xa)" in order_trans)
  apply simp_all
  apply (case_tac "mono (step D)")
  apply (simp add: mono_def)
  apply (simp_all add: le_fun_def)
  apply (rule_tac y = "(assume (- grd (step D)) x xa)" in order_trans)
  apply simp_all
  apply (case_tac "mono (assume (- grd (step D)))")
  apply (simp add: mono_def le_fun_def)
  by simp

definition
  "pt D = lfp (dgr D)"

text {*
If $U$ is an indexed predicate transformer and if $P, Q:I\to \mathit{State} \ \mathit{set}$
are indexed predicates, then the meaning of the Hoare triple defined earlier,
$\models P \{ | U | \} Q$, is that if
we start $U$ in a state $s$ from a situation $i$ such that $s\in P\, i$,
then U terminates, and if it terminates in $s'$ and situation $j$, then
$s'\in Q\ j$ is true.

Next theorem shows that in a diagram all transitions are correct
if and only if $\mathit{step}\ D$ is correct.
*}



theorem hoare_step:
  "(\<forall> i j . \<Turnstile> (P i) {| D(i,j) |} (Q j) ) = (\<Turnstile> P {| step D |} Q)"
  apply safe
  apply (simp add: le_fun_def Hoare_def step_def)
  apply safe
  apply (rule le_INFI)
  apply auto
  apply (simp add: le_fun_def Hoare_def step_def)
  apply (erule_tac x = i in allE)
  apply (rule_tac y = "INF j. D(i, j) (Q j)" in order_trans)
  apply auto
  apply (rule INF_leI)
  by auto

text {*
Next theorem provides the first proof rule for total correctnes of transition
diagrams. If all transitions are correct and if a global variant decreases 
on every transition then the diagram is correct and it terminates. The variant
must decrease according to a well founded and transitive relation.
*}

theorem hoare_diagram:
  "dmono D \<Longrightarrow> (\<forall> w i j . \<Turnstile> X w i  {| D(i,j) |} SUP_L X w j) \<Longrightarrow> 
    \<Turnstile> SUP X {| pt D |} ((SUP X) \<sqinter> -(grd (step D)))"
  apply (simp add: hoare_step pt_def)
  apply (rule hoare_fixpoint)
  apply auto
  apply (simp add: dgr_def)
  apply (simp add: hoare_choice)
  apply safe
  apply (simp add: hoare_sequential)
  apply auto
  apply (simp add: hoare_assume)
  apply (rule le_infI1)
  by (rule SUP_upper)

text{*
This theorem is a more general form of the more familiar form with a variant $t$
which must decrease. If we take $X\ w\ i = (Y \ i \land t\ i = w)$, then the
second hypothesis of the theorem above becomes
$\models Y \ i \land t\ i = w \{| D(i,j) |\} Y \ i \land t \ i < w$. However,
the more general form of the theorem is needed, because
in data refinements, the form $Y\ i \land t\ i = w$ cannot be preserved.
*}

text {*
The drawback of this theorem is that the variant must be decreased on every
transitions which may be too cumbersome for practical applications. A similar 
situation occur when introducing proof rules for mutually recursive procedures.
There the straightforward generalization of the proof rule of a recursive procedure
to mutually recursive procedures suffers of a similar problem. We would need
to prove that the variant decreases before every recursive call. Nipkow
\cite{nipkow:2002} has introduced a rule for mutually recursive procedures
in which the variant is required to decrease only in a sequence of recursive
calls before calling again a procedure in this sequence. We introduce a
similar proof rule in which the variant depends also on the situation
indexes.
*}

locale DiagramTermination =
  fixes pair:: "'a \<Rightarrow> 'b \<Rightarrow> ('c::well_founded_transitive)"
begin

definition
  "SUP_L_P X u i = SUPR {v . pair v i < u} (\<lambda> v . X v i)" 

definition 
  "SUP_LE_P X u i = SUPR {v . pair v i \<le> u} (\<lambda> v . X v i)"

lemma SUP_L_P_upper:
  "pair v i < u \<Longrightarrow> P v i \<le> SUP_L_P P u i"
  by (simp add: SUP_L_P_def SUPR_def Sup_upper)

lemma SUP_L_P_least:
  "(!! v . pair v i < u \<Longrightarrow> P v i \<le> Q) \<Longrightarrow> SUP_L_P P u i \<le> Q"
  by (simp add: SUP_L_P_def SUPR_def, rule Sup_least, auto)

lemma SUP_LE_P_upper:
  "pair v i \<le> u \<Longrightarrow> P v i \<le> SUP_LE_P P u i"
  by (simp add: SUP_LE_P_def SUPR_def Sup_upper)

lemma SUP_LE_P_least:
  "(!! v . pair v i \<le> u \<Longrightarrow> P v i \<le> Q) \<Longrightarrow> SUP_LE_P P u i \<le> Q"
  by (simp add: SUP_LE_P_def SUPR_def, rule Sup_least, auto)

lemma SUP_SUP_L [simp]:
  "SUP (SUP_LE_P X) = SUP X"
  apply (simp add: fun_eq_iff SUP_fun_eq, clarify)
  apply (rule antisym)
  apply (rule SUP_least)
  apply (rule SUP_LE_P_least)
  apply (rule SUP_upper)
  apply (rule SUP_least)
  apply (rule_tac y = "SUP_LE_P X (pair w x) x" in  order_trans)
  apply (rule SUP_LE_P_upper, simp)
  by (rule SUP_upper)

lemma SUP_L_SUP_LE_P [simp]:
  "SUP_L (SUP_LE_P X) = SUP_L_P X"
  apply (simp add: fun_eq_iff SUP_fun_eq SUP_L_fun_eq, clarify)
  apply (rule antisym)
  apply (rule SUP_L_least)
  apply (rule SUP_LE_P_least)
  apply (rule SUP_L_P_upper, simp)
  apply (rule SUP_L_P_least)
  apply (rule_tac y = "SUP_LE_P X (pair v xa) xa" in order_trans)
  apply (rule SUP_LE_P_upper, simp)
  by (rule SUP_L_upper)
  
end
    
theorem (in DiagramTermination) hoare_diagram2:
  "dmono D \<Longrightarrow> (\<forall> u i j . \<Turnstile> X u i  {| D(i, j) |} SUP_L_P X (pair u i) j) \<Longrightarrow> 
    \<Turnstile> SUP X {| pt D |} ((SUP X) \<sqinter> (-(grd (step D))))"
  apply (frule_tac X = "SUP_LE_P X" in hoare_diagram)
  apply auto
  apply (simp add: SUP_LE_P_def SUPR_def)
  apply (rule hoare_Sup)
  apply auto
  apply (rule_tac Q = "SUP_L_P X (pair p i) j" in hoare_mono)
  apply auto
  apply (rule SUP_L_P_least)
  apply (rule SUP_L_P_upper)
  apply (rule order_trans3)
  by auto

lemma mono_pt [simp]: "dmono D \<Longrightarrow> mono (pt D)"
  apply (drule mono_mono_dgr)
  by (simp add: pt_def)

theorem (in DiagramTermination) hoare_diagram3:
  "dmono D \<Longrightarrow> 
     (\<forall> u i j . \<Turnstile> X u i  {| D(i, j) |} SUP_L_P X (pair u i) j) \<Longrightarrow> 
      P \<le> SUP X \<Longrightarrow>  ((SUP X) \<sqinter> (-(grd (step D)))) \<le> Q \<Longrightarrow>
      \<Turnstile> P {| pt D |} Q"
  apply (rule hoare_mono)
  apply auto
  apply (rule hoare_pre)
  apply auto
  apply (rule hoare_diagram2)
  by auto

text{*
The following definition introduces the concept of correct Hoare triples for diagrams.
*}

definition (in DiagramTermination)
  Hoare_dgr :: "('b \<Rightarrow> ('u::{complete_lattice, boolean_algebra})) \<Rightarrow> ('b \<times> 'b \<Rightarrow> 'u \<Rightarrow> 'u) \<Rightarrow> ('b \<Rightarrow> 'u) \<Rightarrow> bool" ("\<turnstile> (_){| _ |}(_) " 
  [0,0,900] 900) where
  "\<turnstile> P {| D |} Q \<equiv> (\<exists> X . (\<forall> u i j . \<Turnstile> X u i  {| D(i, j) |} SUP_L_P X (pair u i) j) \<and> 
       P = SUP X \<and> Q = ((SUP X) \<sqinter> (-(grd (step D)))))"

definition (in DiagramTermination)
  Hoare_dgr1 :: "('b \<Rightarrow> ('u::{complete_lattice, boolean_algebra})) \<Rightarrow> ('b \<times> 'b \<Rightarrow> 'u \<Rightarrow> 'u) \<Rightarrow> ('b \<Rightarrow> 'u) \<Rightarrow> bool" ("\<turnstile>1 (_){| _ |}(_) " 
  [0,0,900] 900) where
  "\<turnstile>1 P {| D |} Q \<equiv> (\<exists> X . (\<forall> u i j . \<Turnstile> X u i  {| D(i, j) |} SUP_L_P X (pair u i) j) \<and> 
      P \<le> SUP X \<and> ((SUP X) \<sqinter> (-(grd (step D)))) \<le> Q)"


theorem (in DiagramTermination) hoare_dgr_correctness: 
  "dmono D \<Longrightarrow> (\<turnstile> P {| D |} Q) \<Longrightarrow> (\<Turnstile> P {| pt D |} Q)"
  apply (simp add: Hoare_dgr_def)
  apply safe
  apply (rule hoare_diagram3)
  by auto

theorem  (in DiagramTermination) hoare_dgr_correctness1:
  "dmono D \<Longrightarrow> (\<turnstile>1 P {| D |} Q) \<Longrightarrow> (\<Turnstile> P {| pt D |} Q)"
  apply (simp add: Hoare_dgr1_def)
  apply safe
  apply (rule hoare_diagram3)
  by auto

definition
  "dgr_demonic Q ij = demonic (Q ij)"

theorem dgr_demonic_mono[simp]:
  "dmono (dgr_demonic Q)"
  by (simp add: dmono_def dgr_demonic_def)

definition
  "dangelic R Q i = angelic (R i) (Q i)"

theorem dangelic_udisjunctive:
  "dangelic R ((SUP P)::('b\<Rightarrow>('a::distributive_complete_lattice))) = SUP (\<lambda> w . dangelic R (P w))"
  by (simp add: fun_eq_iff SUP_fun_eq dangelic_def angelic_udisjunctive)

theorem dangelic_udisjunctive1:
  "dangelic R ((Sup P)::('b\<Rightarrow>('a::distributive_complete_lattice))) = (SUP p:P . dangelic R p)"
  by (simp add: fun_eq_iff SUPR_def Sup_fun_def dangelic_def angelic_udisjunctive1 Sup_bool_def)

theorem (in DiagramTermination) dangelic_udisjunctive2:
  "SUP_L_P (\<lambda>w. (dangelic R) ((P w)::('b \<Rightarrow> ('u::distributive_complete_lattice))) )(pair u i) = dangelic R (SUP_L_P P (pair u i))"
  apply (simp add: fun_eq_iff)
  apply (simp add: dangelic_def)
  apply (simp add: SUP_L_P_def)
  apply (unfold SUPR_def)
  apply (unfold Union_def)
  apply (simp add: dangelic_def)
  apply (unfold angelic_udisjunctive1)
  by auto

lemma  grd_dgr:
  "((grd (step D) i)::('a::complete_boolean_algebra)) = \<Squnion> {P . \<exists> j . P = grd (D(i,j))}"
  apply (simp add: grd_def step_def)
  apply (simp add: neg_fun_pred)
  apply (unfold  step_def)
  apply (unfold INFI_def)
  apply (unfold compl_Inf)
  apply (unfold SUPR_def)
  apply (simp_all add: bot_fun_def)
  apply (case_tac "(uminus ` range (\<lambda>j\<Colon>'b. D (i, j) \<bottom>)) = {P\<Colon>'a. \<exists>j\<Colon>'b. P = - D (i, j) \<bottom>}")
  by auto

lemma  grd_dgr_set:
  "((grd (step D) i)::('a set)) = Union {P . \<exists> j . P = grd (D(i,j))}"
  by (simp add: grd_dgr)

lemma not_grd_dgr [simp]: "(a \<in> (- grd (step D) i)) = (\<forall> j . a \<notin> grd (D(i,j)))"
 apply (simp add: grd_dgr)
  by auto

lemma not_grd_dgr2 [simp]: "(- grd (step D) i a) = (\<forall> j . a \<notin> grd (D(i,j)))"
 apply (case_tac "(- grd (step D) i a) = (a \<in> (- grd (step D) i))")
  apply(simp add: not_grd_dgr)
 apply (simp add: grd_dgr)
 apply auto
  by (simp_all add: mem_def bool_Compl_def)

end

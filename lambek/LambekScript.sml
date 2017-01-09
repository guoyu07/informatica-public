(*
 * A HOL Toolkit for Lambek Calculus & Categorial Type Logics
 *
 * (based on `A Coq Toolkit for Lambek Calculus` (https://github.com/coq-contribs/lambek)
 *
 * Copyright 2016  University of Bologna, Italy (Author: Chun Tian)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
 * WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
 * MERCHANTABLITY OR NON-INFRINGEMENT.
 * See the Apache 2 License for the specific language governing permissions and
 * limitations under the License.
 *)

(* Brief usage for non-HOL users: (Linux & Mac OS X only)
 *
 *  1. Download & install Poly/ML 5.6 from http://www.polyml.org
 *  2. Download & install HOL4 (kananaskis-11) from https://hol-theorem-prover.org
 *  3. Put HOL4's "bin" directory into your PATH;
 *  4. Execute `Holmake` in current directory (in qui si trova "LambekScript.sml")
 *  5. Check LambekTheory.sig for a list of all definitions and theorems
 *  6. Start HOL by executing `hol` in current directory
 *  7. Execute: load "LambekTheory";
 *  8. Execute: open LambekTheory;
 *)

open HolKernel Parse boolLib bossLib;

open relationTheory;

val _ = new_theory "Lambek";

(*** Module: Form ***)

val _ = Datatype `Form = At 'a | Slash Form Form | Backslash Form Form | Dot Form Form`;

(* or val _ = overload_on ("*", Term `Dot`); *)
val _ = set_mapped_fixity { fixity = Infix(NONASSOC, 450), tok = ".", term_name = "Dot" };
val _ = set_mapped_fixity { fixity = Infix(LEFT, 1000), tok = "/", term_name = "Slash" };
val _ = set_mapped_fixity { fixity = Infix(RIGHT, 1500), tok = "\\", term_name = "Backslash" };

(** The arrow relationship and its extensions (like associativity, commutativity  etc.) **)

val _ = type_abbrev ("arrow_extension", ``:'a Form -> 'a Form -> bool``);

val add_extension_def = Define `add_extension E1 E2 = E1 RUNION E2`;
val extends_def = Define `extends X X' = X RSUBSET X'`;

val no_extend = store_thm ("no_extend", ``!X. extends X X``,
    RW_TAC std_ss [extends_def, RSUBSET]);

val add_extend_l = store_thm ("add_extend_l", ``!X X'. extends X (add_extension X X')``,
    RW_TAC std_ss [extends_def, add_extension_def, RSUBSET, RUNION]);

val add_extend_r = store_thm ("add_extend_r", ``!X X'. extends X' (add_extension X X')``,
    RW_TAC std_ss [extends_def, add_extension_def, RSUBSET, RUNION]);

val extends_trans = store_thm ("extends_trans",
  ``!X Y Z. extends X Y /\ extends Y Z ==> extends X Z``,
    RW_TAC std_ss [extends_def, RSUBSET]);

val extends_transitive = store_thm ("extends_trans", ``transitive extends``,
    REWRITE_TAC [transitive_def, extends_trans]);

val _ = set_mapped_fixity { fixity = Infix(NONASSOC, 450), tok = "-->", term_name = "arrow" };
val _ = Unicode.unicode_version {u = UnicodeChars.rightarrow, tmnm = "arrow"};

(* Most primitive rules of Lambek's syntactic calculus *)
val (p_arrow_rules, _ , _) = Hol_reln `
    (!A B C. p_arrow (Dot A B) C ==> p_arrow A (Slash C B))	/\ (* c  / beta   *)
    (!A B C. p_arrow A (Slash C B) ==> p_arrow (Dot A B) C)	/\ (* d  / beta'  *)
    (!A B C. p_arrow (Dot A B) C ==> p_arrow B (Backslash A C))	/\ (* c' / gamma  *)
    (!A B C. p_arrow B (Backslash A C) ==> p_arrow (Dot A B) C)	/\ (* d' / gamma' *)
    (!X A B. X A B ==> p_arrow A B) `;				   (* arrow_plus  *)

(* Define `arrow` as the reflexive transitive closure (RTC) of `p_arrow` *)
val arrow_def = Define `arrow = RTC p_arrow`;

val one = store_thm ("one", ``!A. arrow A A``,
    REWRITE_TAC [arrow_def, p_arrow_rules, RTC_REFL]);

local
  val t = PROVE_TAC [arrow_def, p_arrow_rules, RTC_DEF]
in
  val comp = store_thm ("comp", ``!A B C. arrow A B /\ arrow B C ==> arrow A C``, t)
  and beta = store_thm ("beta", ``(!A B C. arrow (Dot A B) C ==> arrow A (Slash C B))``, t)
  and beta' = store_thm ("beta'", ``(!A B C. arrow A (Slash C B) ==> arrow (Dot A B) C)``, t)
  and gamma = store_thm ("gamma", ``(!A B C. arrow (Dot A B) C ==> arrow B (Backslash A C))``, t)
  and gamma' = store_thm ("gamma'", ``(!A B C. arrow B (Backslash A C) ==> arrow (Dot A B) C)``, t)
  and arrow_plus = store_thm ("arrow_plus", ``(!X A B. X A B ==> arrow A B)``, t)
end;

(** most popular extensions **)

val NL_def = Define `NL = EMPTY_REL`;

val (L_rules, _ , _) = Hol_reln `
    (!A B C. L (Dot A (Dot B C)) (Dot (Dot A B) C)) /\
    (!A B C. L (Dot (Dot A B) C) (Dot A (Dot B C))) `;

val (NLP_rules, _, _) = Hol_reln `
    (!A B. NLP (Dot A B) (Dot B A)) `;

val LP_def = Define `LP = add_extension NLP L`;

val NL_X = store_thm ("NL_X", ``!X. extends NL X``,
    RW_TAC std_ss [extends_def, NL_def, EMPTY_REL_DEF, RSUBSET]);

val NLP_LP = store_thm ("NLP_LP", ``extends NLP LP``,
    REWRITE_TAC [LP_def, add_extend_l]);

val L_LP = store_thm ("L_LP", ``extends L LP``,
    REWRITE_TAC [LP_def, add_extend_r]);

(* from p_arrow_rules to arrow_rules, this is actually all primitive rules for NL *)
val arrow_rules = LIST_CONJ [one, comp, beta, beta', gamma, gamma', arrow_plus];

(* Some derived rules for arrow.
   Note: all theorems here can be simply proved by PROVE_TAC [arrow_rules]. *)

val Dot_mono_right = store_thm ("Dot_mono_right",
  ``!A B B'. arrow B' B ==> arrow (Dot A B') (Dot A B)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC gamma'
 >> MATCH_MP_TAC comp
 >> EXISTS_TAC ``B:'a Form``
 >> CONJ_TAC
 >| [ ASM_REWRITE_TAC [],
      MATCH_MP_TAC gamma >> RW_TAC std_ss [one] ]);

val Dot_mono_left = store_thm ("Dot_mono_left",
  ``!A B A'. arrow A' A ==> arrow (Dot A' B) (Dot A B)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC beta'
 >> MATCH_MP_TAC comp
 >> EXISTS_TAC ``A:'a Form``
 >> CONJ_TAC
 >| [ ASM_REWRITE_TAC [],
      MATCH_MP_TAC beta >> RW_TAC std_ss [one] ]);
		  
val Dot_mono = store_thm ("Dot_mono",
  ``!A B C D. arrow A C /\ arrow B D ==> arrow (Dot A B) (Dot C D)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC comp
 >> EXISTS_TAC ``Dot C B``
 >> CONJ_TAC
 >| [ MATCH_MP_TAC Dot_mono_left >> RW_TAC std_ss [],
      MATCH_MP_TAC Dot_mono_right >> RW_TAC std_ss [] ]);

val Slash_mono_left = store_thm ("Slash_mono_left",
  ``!C B C'. arrow C' C ==> arrow (Slash C' B) (Slash C B)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC beta
 >> MATCH_MP_TAC comp
 >> EXISTS_TAC ``C':'a Form``
 >> CONJ_TAC
 >| [ MATCH_MP_TAC beta' >> RW_TAC std_ss [one], RW_TAC std_ss [] ]);

val Slash_antimono_right = store_thm ("Slash_antimono_right",
  ``!C B B'. arrow B' B ==> arrow (Slash C B) (Slash C B')``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC beta
 >> MATCH_MP_TAC gamma'
 >> MATCH_MP_TAC comp
 >> EXISTS_TAC ``B:'a Form``
 >> CONJ_TAC
 >| [ ASM_REWRITE_TAC [],
      MATCH_MP_TAC gamma >> MATCH_MP_TAC beta' >> RW_TAC std_ss [one] ]);

val Backslash_antimono_left = store_thm ("Backslash_antimono_left",
  ``!A C A'. arrow A A' ==> arrow (Backslash A' C) (Backslash A C)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC gamma
 >> MATCH_MP_TAC beta'
 >> MATCH_MP_TAC comp
 >> EXISTS_TAC ``A':'a Form``
 >> CONJ_TAC
 >| [ ASM_REWRITE_TAC [],
      MATCH_MP_TAC beta >> MATCH_MP_TAC gamma' >> RW_TAC std_ss [one] ]);

val Backslash_mono_right = store_thm ("Backslash_mono_right",
  ``!A C C'. arrow C' C ==> arrow (Backslash A C') (Backslash A C)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC gamma
 >> MATCH_MP_TAC comp
 >> EXISTS_TAC ``C':'a Form``
 >> CONJ_TAC
 >| [ MATCH_MP_TAC beta' >> MATCH_MP_TAC beta >>
      MATCH_MP_TAC gamma' >> RW_TAC std_ss [one],
      ASM_REWRITE_TAC [] ]);

(* extended version of the arrow relation *)
val Arrow_def = Define `Arrow X = add_extension arrow X`;

val mono_X = store_thm ("mono_X",
  ``!X X'. extends X X' ==> (!A B. Arrow X A B ==> Arrow X' A B)``,
    RW_TAC std_ss [extends_def, Arrow_def, add_extension_def, RSUBSET, RUNION]
    THENL [ DISJ1_TAC >> RW_TAC std_ss [],
	    DISJ2_TAC >> RW_TAC std_ss [] ]);

val X_Arrow = store_thm ("X_arrow", ``!X A B. X A B ==> Arrow X A B``,
    RW_TAC std_ss [Arrow_def, add_extension_def, RUNION, RSUBSET]);

val arrow_Arrow = store_thm ("arrow_Arrow", ``!X A B. arrow A B ==> Arrow X A B``,
    RW_TAC std_ss [Arrow_def, add_extension_def, RUNION, RSUBSET]);

val Arrow_NLP = store_thm ("Arrow_NLP", ``!A B. Arrow NLP (Dot A B) (Dot B A)``,
    RW_TAC std_ss [NLP_rules, X_Arrow]);

(* Standard (full) Lambek arrow *)
val arrow_L_def = Define `arrow_L = Arrow L`;

val _ = set_mapped_fixity { fixity = Infix(NONASSOC, 450), tok = "L->", term_name = "arrow_L" };
val _ = Unicode.unicode_version {u = UnicodeChars.rightarrow ^ UnicodeChars.sup_l, tmnm = "arrow_L"};

val L_a = store_thm ("L_a", ``!x. arrow_L x x``, RW_TAC std_ss [arrow_L_def, arrow_Arrow, one]);

local
  val t = PROVE_TAC [arrow_L_def, arrow_Arrow, arrow_rules, L_rules]
in
  val L_b  = store_thm ("L_b",  ``!x y z. arrow_L (Dot (Dot x y) z) (Dot x (Dot y z))``, t)
  and L_b' = store_thm ("L_b'", ``!x y z. arrow_L (Dot x (Dot y z)) (Dot (Dot x y) z)``, t)
end;

local
  val t = PROVE_TAC [arrow_L_def, arrow_Arrow, arrow_rules]
in
  val L_c  = store_thm ("L_c",  ``!x y z. arrow_L (Dot x y) z ==> arrow_L x (Slash z y)``, t)
  and L_c' = store_thm ("L_c'", ``!x y z. arrow_L (Dot x y) z ==> arrow_L y (Backslash x z)``, t)
  and L_d  = store_thm ("L_d",  ``!x y z. arrow_L x (Slash z y) ==> arrow_L (Dot x y) z``, t)
  and L_d' = store_thm ("L_d'", ``!x y z. arrow_L y (Backslash x z) ==> arrow_L (Dot x y) z``, t)
  and L_e  = store_thm ("L_e",  ``!x y z. arrow_L x y /\ arrow_L y z ==> arrow_L x z``, t);

  val arrow_L_rules = LIST_CONJ [L_a, L_b, L_b', L_c, L_c', L_d, L_d', L_e];
end;

local
  val t = PROVE_TAC [arrow_L_rules]
in
  val L_f  = store_thm ("L_f",  ``!x y. arrow_L x (Slash (Dot x y) y)``, t)
  and L_g  = store_thm ("L_g",  ``!y z. arrow_L (Dot (Slash z y) y) z``, t)
  and L_h  = store_thm ("L_h",  ``!y z. arrow_L y (Backslash (Slash z y) z)``, t)
  and L_i  = store_thm ("L_i",  ``!x y z. arrow_L (Dot (Slash z y) (Slash y x)) (Slash z x)``, t)
  and L_j  = store_thm ("L_j",  ``!x y z. arrow_L (Slash z y) (Slash (Slash z x) (Slash y x))``, t)
  and L_k  = store_thm ("L_k",  ``!x y z. arrow_L (Slash (Backslash x y) z) (Backslash x (Slash y z))``, t)
  and L_k' = store_thm ("L_k'", ``!x y z. arrow_L (Backslash x (Slash y z)) (Slash (Backslash x y) z)``, t)
  and L_l  = store_thm ("L_l",  ``!x y z. arrow_L (Slash (Slash x y) z) (Slash x (Dot z y))``, t)
  and L_l' = store_thm ("L_l'", ``!x y z. arrow_L (Slash x (Dot z y)) (Slash (Slash x y) z)``, t)
  and L_m  = store_thm ("L_m",  ``!x x' y y'. arrow_L x x' /\ arrow_L y y'
					  ==> arrow_L (Dot x y) (Dot x' y')``, t)
  and L_n  = store_thm ("L_n",  ``!x x' y y'. arrow_L x x' /\ arrow_L y y'
					  ==> arrow_L (Slash x y') (Slash x' y)``, t);
  
  val arrow_L_rules_ex = LIST_CONJ [L_f, L_g, L_h, L_i, L_j, L_k, L_k', L_l, L_l', L_m, L_n]
end;

local
  val t = PROVE_TAC [L_a, L_c, L_c', L_d, L_d', L_e] (* L_b and L_b' are not used *)
in
  val L_dot_mono_r = store_thm ("L_dot_mono_r",
      ``!A B B'. arrow_L B B' ==> arrow_L (Dot A B) (Dot A B')``, t)
  and L_dot_mono_l = store_thm ("L_dot_mono_l",
      ``!A B A'. arrow_L A A' ==> arrow_L (Dot A B) (Dot A' B)``, t)
  and L_slash_mono_l = store_thm ("L_slash_mono_l",
      ``!C B C'. arrow_L C C' ==> arrow_L (Slash C B) (Slash C' B)``, t)
  and L_slash_antimono_r = store_thm ("L_slash_antimono_r",
      ``!C B B'. arrow_L B B' ==> arrow_L (Slash C B') (Slash C B)``, t)
  and L_backslash_antimono_l = store_thm ("L_backslash_antimono_l",
      ``!A C A'. arrow_L A A' ==> arrow_L (Backslash A' C) (Backslash A C)``, t)
  and L_backslash_mono_r = store_thm ("L_backslash_mono_r",
      ``!A C C'. arrow_L C C' ==> arrow_L (Backslash A C) (Backslash A C')``, t);

  val arrow_L_rules_mono = LIST_CONJ [L_dot_mono_r, L_dot_mono_l,
				      L_slash_mono_l, L_slash_antimono_r,
				      L_backslash_antimono_l, L_backslash_mono_r]
end;

(* combinators: pi and alpha *)
(*
local
   val lem = SPECL [``NLP:'a arrow_extension``, ``X:'a arrow_extension``] mono_X
in
   val pi = store_thm ("pi", ``!X. extends NLP X ==> !A B. Arrow X (Dot A B) (Dot B A)``, t)
end
*)

(*** Module: Terms ***)

val _ = Datatype `Term = OneForm ('a Form) | Comma Term Term`;

val _ = add_rule { term_name = "Comma", fixity = Infix(LEFT, 500),
		   pp_elements = [HardSpace 0, TOK "," , BreakSpace(1,0)],
		   paren_style = Always,
		   block_style = (AroundEachPhrase, (PP.INCONSISTENT, 0)) };

val _ = type_abbrev ("gentzen_extension", ``:'a Term -> 'a Term -> bool``);

(* Definition of the recursive function that translates Terms to Forms *)
val deltaTranslation_def = Define `
    (deltaTranslation (OneForm f) = f) /\
    (deltaTranslation (Comma t1 t2) = Dot (deltaTranslation t1) (deltaTranslation t2))`;

(* Definition of the relation that connects arrow_extension with gentzen_extension *)
val implements_def = Define
   `implements (X:'a arrow_extension) (E:'a gentzen_extension) =
    (!(A:'a Term) (B:'a Term). E A B = X (deltaTranslation A) (deltaTranslation B))`;

(* NL Sequent extension, an empty relation actually *)
val NL_Sequent_def = Define `NL_Sequent A B = NL (deltaTranslation A) (deltaTranslation B)`;

val NL_implements_NL_Sequent = store_thm ("NL_implements_NL_Sequent",
  ``implements NL NL_Sequent``,
    RW_TAC std_ss [NL_Sequent_def, implements_def]);

(* NLP Sequent extension *)
val NLP_Sequent_def = Define `NLP_Sequent A B = NLP (deltaTranslation A) (deltaTranslation B)`;

val NLP_implements_NLP_Sequent = store_thm ("NLP_implements_NLP_Sequent",
  ``implements NLP NLP_Sequent``,
    RW_TAC std_ss [NLP_Sequent_def, implements_def]);

val NLP_Intro = store_thm ("NLP_Intro", ``!A B. NLP_Sequent (Comma A B) (Comma B A)``,
    RW_TAC std_ss [deltaTranslation_def, NLP_Sequent_def, NLP_rules]);

(* L Sequent extension, the Full Lambek Sequent Calculus extension *)
val L_Sequent_def = Define `L_Sequent A B = L (deltaTranslation A) (deltaTranslation B)`;

val L_implements_L_Sequent = store_thm ("L_implements_L_Sequent",
  ``implements L L_Sequent``,
    RW_TAC std_ss [L_Sequent_def, implements_def]);

(* two important L_Intro rules now become theorems *)
local
  val t = RW_TAC std_ss [deltaTranslation_def, L_Sequent_def, L_rules]
in
  val L_Intro_lr = store_thm ("L_Intro_lr",
    ``!A B C. L_Sequent (Comma A (Comma B C)) (Comma (Comma A B) C)``, t)
  and L_Intro_rl = store_thm ("L_Intro_rl",
    ``!A B C. L_Sequent (Comma (Comma A B) C) (Comma A (Comma B C))``, t)
end;

val LP_Sequent_def = Define `LP_Sequent = add_extension NLP_Sequent L_Sequent`;

val LP_extends_L = store_thm ("LP_extends_L",
  ``!E. extends LP_Sequent E ==> extends L_Sequent E``,
    RW_TAC std_ss [LP_Sequent_def, extends_def, add_extension_def, RSUBSET, RUNION]);

val LP_extends_NLP = store_thm ("LP_extends_NLP",
  ``!E. extends LP_Sequent E ==> extends NLP_Sequent E``,
    RW_TAC std_ss [LP_Sequent_def, extends_def, add_extension_def, RSUBSET, RUNION]);

val LP_implements_LP_Sequent = store_thm ("LP_implements_LP_Sequent",
  ``implements LP LP_Sequent``,
    REWRITE_TAC [implements_def]
 >> RW_TAC std_ss [LP_def, LP_Sequent_def]
 >> REWRITE_TAC [add_extension_def, RUNION]
 >> RW_TAC std_ss [NLP_Sequent_def, L_Sequent_def]);

(*** Module: ReplaceProp ***)

(* The `replace` operator has the type ('a ReplaceProp) *)
val _ = type_abbrev ("ReplaceProp", ``:'a Term -> 'a Term -> 'a Term -> 'a Term -> bool``);

(* Inductive definition of `replace` such that when ``replace Gamma Gamma' Delta Delta'``
   then Gamma' results from replacing a distinguished occurrence of the subterm Delta in
   the term Gamma by Delta' *)

val (replace_rules, _ , _) = Hol_reln `
    (!F1 F2. replace F1 F2 F1 F2) /\					(* replaceRoot *)
    (!Gamma1 Gamma2 Delta F1 F2.
     replace Gamma1 Gamma2 F1 F2 ==>
     replace (Comma Gamma1 Delta) (Comma Gamma2 Delta) F1 F2) /\	(* replaceLeft *)
    (!Gamma1 Gamma2 Delta F1 F2.
     replace Gamma1 Gamma2 F1 F2 ==>
     replace (Comma Delta Gamma1) (Comma Delta Gamma2) F1 F2)`;		(* replaceRight *)

val [replaceRoot, replaceLeft, replaceRight] = CONJ_LIST 3 replace_rules;

(* Definition of `replaceCommaDot` such that when ``replaceCommaDot Gamma Gamma'``
   then Gamma' is the result of replacing a number of commas in Gamma by the connector dot.

   Example: ``!A B. replaceCommaDot (A , (A , B)) (A , (A . B)))`` where in this case only
   one occurrence of comma is replaced by a dot. *)

val (replaceCommaDot1_rules, _ , replaceCommaDot1_cases) = Hol_reln `
    (!T1 T2 A B.
     replace T1 T2 (Comma (OneForm A) (OneForm B)) (OneForm (Dot A B)) ==>
     replaceCommaDot1 T1 T2)`;

val replaceCommaDot_def = Define `replaceCommaDot = RTC replaceCommaDot1`;

val replaceTransitive = store_thm ("replaceTransitive", ``transitive replaceCommaDot``,
    REWRITE_TAC [replaceCommaDot_def, RTC_TRANSITIVE]);

(* a more practical version *)
val replaceTransitive' = store_thm ("replaceTransitive'",
  ``!T1 T2 T3. replaceCommaDot T1 T2 /\ replaceCommaDot T2 T3 ==> replaceCommaDot T1 T3``,
    PROVE_TAC [replaceTransitive, transitive_def]);

val noReplace = store_thm ("noReplace", ``!T. replaceCommaDot T T``,
    PROVE_TAC [replaceCommaDot_def, RTC_REFLEXIVE, reflexive_def]);

local
  val t = PROVE_TAC [replaceCommaDot1_rules, replaceCommaDot_def, replaceTransitive,
		     transitive_def, RTC_SINGLE]
in
  val replaceOneComma = store_thm ("replaceOneComma",
    ``!T1 T2 T3 A B.
      replaceCommaDot T1 T2 /\
      replace T2 T3 (Comma (OneForm A) (OneForm B)) (OneForm (Dot A B))
      ==> replaceCommaDot T1 T3``, t)

  and replaceOneComma' = store_thm ("replaceOneComma'",
    ``!T1 T2 T3 A B.
      replace T1 T2 (Comma (OneForm A) (OneForm B)) (OneForm (Dot A B)) /\
      replaceCommaDot T2 T3
      ==> replaceCommaDot T1 T3``, t);

  val replaceCommaDot_rules = LIST_CONJ [noReplace, replaceOneComma, replaceOneComma']
end;

(* An induction theorem for RTC replaceCommaDot1, similar to those generated by Hol_reln *)
val replaceCommaDot_ind = store_thm ("replaceCommaDot_ind",
  ``!(P:'a gentzen_extension).
     (!x. P x x) /\
     (!x y z A B.
       replace x y (Comma (OneForm A) (OneForm B)) (OneForm (Dot A B)) /\ P y z ==> P x z)
     ==> (!x y. replaceCommaDot x y ==> P x y)``,
 (* The idea is to use RTC_INDUCT thm to prove induct theorems for RTCs *)
    REWRITE_TAC [replaceCommaDot_def]
 >> GEN_TAC   (* remove outer !P *)
 >> STRIP_TAC (* prepare for higher order matching *)
 >> HO_MATCH_MP_TAC (ISPEC ``replaceCommaDot1:'a gentzen_extension`` RTC_INDUCT)
 >> PROVE_TAC [replaceCommaDot1_cases]);

local
  val t = GEN_TAC (* prepare for higher order matching and induction *)
	  >> HO_MATCH_MP_TAC replaceCommaDot_ind
	  >> PROVE_TAC [replace_rules, replaceCommaDot_rules]
in
  val replaceMonoRight = store_thm ("replaceMonoRight",
    ``!T3 T1 T2. replaceCommaDot T1 T2 ==> replaceCommaDot (Comma T1 T3) (Comma T2 T3)``, t)
  and replaceMonoLeft = store_thm ("replaceMonoLeft",
    ``!T3 T1 T2. replaceCommaDot T1 T2 ==> replaceCommaDot (Comma T3 T1) (Comma T3 T2)``, t)
end;

val replaceMono = store_thm ("replaceMono",
  ``!T1 T2 T3 T4. replaceCommaDot T1 T2 /\ replaceCommaDot T3 T4 ==>
		  replaceCommaDot (Comma T1 T3) (Comma T2 T4)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC replaceTransitive'
 >> EXISTS_TAC ``Comma T2 T3``
 >> PROVE_TAC [replaceMonoLeft, replaceMonoRight]);

val replaceTranslation = store_thm ("replaceTranslation",
  ``!T. replaceCommaDot T (OneForm (deltaTranslation T))``,
    Induct
 >| [ PROVE_TAC [deltaTranslation_def, noReplace], (* base case *)
      REWRITE_TAC [deltaTranslation_def]         (* induct case *)
   >> MATCH_MP_TAC replaceTransitive'
   >> EXISTS_TAC ``Comma (OneForm (deltaTranslation T')) (OneForm (deltaTranslation T''))``
   >> PROVE_TAC [replaceOneComma, noReplace, replaceRoot, replaceMono] ]);

(* TODO / remain theorems: replace_inv1, replace_inv2, doubleReplace, replaceSameP, replaceTrans *)

(*** Module: NaturalDeduction ***)

(* TODO: possible alternative definition, the rest rules then become theorems
val natDed'_def = Define `
    natDed' E Gamma A = (!X. implements X E /\ Arrow X (deltaTranslation Gamma) A)`;
 *)

val (natDed_rules, _ , _) = Hol_reln `
    (!A (E:'a gentzen_extension). natDed E (OneForm A) A) /\			(* NatAxiom *)
    (!Gamma A B E.								(* SlashIntro *)
      natDed E (Comma Gamma (OneForm B)) A ==> natDed E Gamma (Slash A B)) /\
    (!Gamma A B E.								(* BackslashIntro *)
      natDed E (Comma (OneForm B) Gamma) A ==> natDed E Gamma (Backslash B A)) /\
    (!Gamma Delta A B E.							(* DotIntro *)
      natDed E Gamma A /\ natDed E Delta B ==> natDed E (Comma Gamma Delta) (Dot A B)) /\
    (!Gamma Delta A B E.							(* SlashElim *)
      natDed E Gamma (Slash A B) /\ natDed E Delta B ==> natDed E (Comma Gamma Delta) A) /\
    (!Gamma Delta A B E.						 	(* BackslashElim *)
      natDed E Gamma B /\ natDed E Delta (Backslash B A) ==> natDed E (Comma Gamma Delta) A) /\
    (!Gamma Gamma' Delta A B C E.						(* DotElim *)
      replace Gamma Gamma' (Comma (OneForm A) (OneForm B)) Delta /\
      natDed E Delta (Dot A B) /\ natDed E Gamma C ==> natDed E Gamma' C) /\
    (!(N:'a gentzen_extension) Gamma Gamma' T1 T2 C E.				(* NatExt *)
      N T1 T2 /\ replace Gamma Gamma' T1 T2 /\ natDed E Gamma C ==> natDed E Gamma' C)`;

(* Break above rules into separated theorems with proper names *)
val [NatAxiom, SlashIntro, BackslashIntro, DotIntro, SlashElim, BackslashElim, DotElim, NatExt] =
    (CONJ_LIST 8 natDed_rules);

val NatAxiomGen = store_thm ("NatAxiomGen", ``!Gamma E. natDed E Gamma (deltaTranslation Gamma)``,
    Induct
 >| [ PROVE_TAC [deltaTranslation_def, NatAxiom], (* base case *)
      REWRITE_TAC [deltaTranslation_def] >>     (* induct case *)
      PROVE_TAC [DotIntro] ]);

val DotElimGeneralized = store_thm ("DotElimGeneralized",
  ``!E T1 T2 C. replaceCommaDot T1 T2 /\ natDed E T1 C ==> natDed E T2 C``,
    PROVE_TAC [replace_rules, replaceCommaDot_rules, natDed_rules]);

(*** Module: Sequent Calculus ***)

(* TODO: possible alternative definition, the rest rules then become theorems
val (gentzenSequent'_rules, _ , _) = Hol_reln `
    (!Gamma A X E.
      implements X E /\ Arrow X (deltaTranslation Gamma) A
      ==> gentzenSequent' E Gamma A) /\
    (!Delta Gamma Gamma' A C E.							(* CutRule *)
      replace Gamma Gamma' (OneForm A) Delta /\
      gentzenSequent' E Delta A /\ gentzenSequent' E Gamma C
      ==> gentzenSequent' E Gamma' C)`;
 *)

val (gentzenSequent_rules, _ , _) = Hol_reln `
    (!A (E:'a gentzen_extension). gentzenSequent E (OneForm A) A) /\		(* SeqAxiom *)
    (!Gamma A B E.								(* RightSlash *)
      gentzenSequent E (Comma Gamma (OneForm B)) A ==>
      gentzenSequent E Gamma (Slash A B)) /\
    (!Gamma A B E.								(* RightBackslash *)
      gentzenSequent E (Comma (OneForm B) Gamma) A ==>
      gentzenSequent E Gamma (Backslash B A)) /\
    (!Gamma Delta A B E.							(* RightDot *)
      gentzenSequent E Gamma A /\ gentzenSequent E Delta B
      ==> gentzenSequent E (Comma Gamma Delta) (Dot A B)) /\
    (!Gamma Gamma' Delta A B C E.						(* LeftSlash *)
      replace Gamma Gamma' (OneForm A) (Comma (OneForm (Slash A B)) Delta) /\
      gentzenSequent E Delta B /\ gentzenSequent E Gamma C
      ==> gentzenSequent E Gamma' C) /\
    (!Gamma Gamma' Delta A B C E.						(* LeftBackslash *)
      replace Gamma Gamma' (OneForm A) (Comma Delta (OneForm (Backslash B A))) /\
      gentzenSequent E Delta B /\ gentzenSequent E Gamma C
      ==> gentzenSequent E Gamma' C) /\
    (!Gamma Gamma' A B C E.							(* LeftDot *)
      replace Gamma Gamma' (Comma (OneForm A) (OneForm B)) (OneForm (Dot A B)) /\
      gentzenSequent E Gamma C
      ==> gentzenSequent E Gamma' C) /\
    (!Delta Gamma Gamma' A C E.							(* CutRule *)
      replace Gamma Gamma' (OneForm A) Delta /\
      gentzenSequent E Delta A /\ gentzenSequent E Gamma C
      ==> gentzenSequent E Gamma' C) /\
    (!(N:'a gentzen_extension) Gamma Gamma' T1 T2 C E.				(* SequentExtension *)
      N T1 T2 /\ replace Gamma Gamma' T1 T2 /\ gentzenSequent E Gamma C
      ==> gentzenSequent E Gamma' C)`;

val [SeqAxiom, RightSlash, RightBackslash, RightDot, LeftSlash, LeftBackslash, LeftDot,
     CutRule, SequentExtension] =
    (CONJ_LIST 9 gentzenSequent_rules);

val SeqAxiomGen = store_thm ("SeqAxiomGen", ``!Gamma E. gentzenSequent E Gamma (deltaTranslation Gamma)``,
    Induct
 >| [ PROVE_TAC [deltaTranslation_def, SeqAxiom], (* base case *)
      REWRITE_TAC [deltaTranslation_def] >>     (* induct case *)
      PROVE_TAC [RightDot] ]);

(* Some derived properties concerning gentzenSequent *)

val LeftDotSimpl = store_thm ("LeftDotSimpl",
  ``!A B C E. gentzenSequent E (Comma (OneForm A) (OneForm B)) C ==>
	      gentzenSequent E (OneForm (Dot A B)) C``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC LeftDot
 >> EXISTS_TAC ``(Comma (OneForm A) (OneForm B))``
 >> EXISTS_TAC ``A:'a Form``
 >> EXISTS_TAC ``B:'a Form``
 >> PROVE_TAC [replaceRoot]);

val LeftDotGeneralized = store_thm ("LeftDotGeneralized",
  ``!T1 T2 C E. replaceCommaDot T1 T2 /\ gentzenSequent E T1 C ==> gentzenSequent E T2 C``,
    PROVE_TAC [replace_rules, replaceCommaDot_rules, gentzenSequent_rules]);

val TermToForm = store_thm ("TermToForm",
  ``!Gamma C E. gentzenSequent E Gamma C
	    ==> gentzenSequent E (OneForm (deltaTranslation Gamma)) C``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC LeftDotGeneralized
 >> EXISTS_TAC ``Gamma:'a Term``
 >> RW_TAC std_ss [replaceTranslation]);

val LeftSlashSimpl = store_thm ("LeftSlashSimpl",
  ``!Gamma A B C E. gentzenSequent E Gamma B /\ gentzenSequent E (OneForm A) C
	        ==> gentzenSequent E (Comma (OneForm (Slash A B)) Gamma) C``,
    PROVE_TAC [replace_rules, replaceCommaDot_rules, LeftSlash]);

val LeftBackslashSimpl = store_thm ("LeftBackslashSimpl",
  ``!Gamma A B C E. gentzenSequent E Gamma B /\ gentzenSequent E (OneForm A) C
	        ==> gentzenSequent E (Comma Gamma (OneForm (Backslash B A))) C``,
    PROVE_TAC [replace_rules, replaceCommaDot_rules, LeftBackslash]);

val CutRuleSimpl = store_thm ("CutRuleSimpl",
  ``!Gamma A C E. gentzenSequent E Gamma A /\ gentzenSequent E (OneForm A) C
	      ==> gentzenSequent E Gamma C``,
    PROVE_TAC [replace_rules, replaceCommaDot_rules, CutRule]);

val DotRightSlash' = store_thm ("DotRightSlash'",
  ``!A B C E. gentzenSequent E (OneForm A) (Slash C B)
	  ==> gentzenSequent E (OneForm (Dot A B)) C``,
    PROVE_TAC [replace_rules, replaceCommaDot_rules, gentzenSequent_rules]);

val DotRightBackslash' = store_thm ("DotRightBackslash'",
  ``!A B C E. gentzenSequent E (OneForm B) (Backslash A C)
	  ==> gentzenSequent E (OneForm (Dot A B)) C``,
    PROVE_TAC [replace_rules, replaceCommaDot_rules, gentzenSequent_rules]);

(* some definitions concerning extensions *)

val LextensionSimpl = store_thm ("LextensionSimpl",
  ``!T1 T2 T3 C E. extends L_Sequent E /\
		   gentzenSequent E (Comma T1 (Comma T2 T3)) C
	       ==> gentzenSequent E (Comma (Comma T1 T2) T3) C``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC SequentExtension
 >> EXISTS_TAC ``L_Sequent:'a gentzen_extension`` (* E *)
 >> EXISTS_TAC ``(Comma T1 (Comma T2 T3))``       (* Gamma *)
 >> EXISTS_TAC ``(Comma T1 (Comma T2 T3))``       (* T1 *)
 >> EXISTS_TAC ``(Comma (Comma T1 T2) T3)``       (* T2 *)
 >> RW_TAC std_ss [extends_def, RUNION, replaceRoot, L_Intro_lr]);

val LextensionSimpl' = store_thm ("LextensionSimpl'", (* dual theorem of above *)
  ``!T1 T2 T3 C E. extends L_Sequent E /\
		   gentzenSequent E (Comma (Comma T1 T2) T3) C
	       ==> gentzenSequent E (Comma T1 (Comma T2 T3)) C``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC SequentExtension
 >> EXISTS_TAC ``L_Sequent:'a gentzen_extension`` (* E *)
 >> EXISTS_TAC ``(Comma (Comma T1 T2) T3)``       (* Gamma *)
 >> EXISTS_TAC ``(Comma (Comma T1 T2) T3)``       (* T1 *)
 >> EXISTS_TAC ``(Comma T1 (Comma T2 T3))``       (* T2 *)
 >> RW_TAC std_ss [extends_def, RUNION, replaceRoot, L_Intro_rl]);

val LextensionSimplDot = store_thm ("LextensionSimplDot",
  ``!A B C D E. extends L_Sequent E /\
		gentzenSequent E (OneForm (Dot A (Dot B C))) D
	    ==> gentzenSequent E (OneForm (Dot (Dot A B) C)) D``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC LeftDotSimpl
 >> MATCH_MP_TAC LeftDot
 >> EXISTS_TAC ``(Comma (Comma (OneForm A) (OneForm B)) (OneForm C))``
 >> EXISTS_TAC ``A:'a Form``
 >> EXISTS_TAC ``B:'a Form``
 >> STRIP_TAC
 >| [ RW_TAC std_ss [replaceLeft, replaceRoot],
      MATCH_MP_TAC LextensionSimpl
   >> STRIP_TAC
   >| [ ASM_REWRITE_TAC [],
	MATCH_MP_TAC CutRuleSimpl
     >> EXISTS_TAC ``(deltaTranslation (Comma (OneForm A) (Comma (OneForm B) (OneForm C))))``
     >> RW_TAC std_ss [SeqAxiomGen, deltaTranslation_def] ] ]);

val LextensionSimplDot' = store_thm ("LextensionSimplDot'", (* dual theorem of above *)
  ``!A B C D E. extends L_Sequent E /\
		gentzenSequent E (OneForm (Dot (Dot A B) C)) D
	    ==> gentzenSequent E (OneForm (Dot A (Dot B C))) D``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC LeftDotSimpl
 >> MATCH_MP_TAC LeftDot
 >> EXISTS_TAC ``(Comma (OneForm A) (Comma (OneForm B) (OneForm C)))``
 >> EXISTS_TAC ``B:'a Form``
 >> EXISTS_TAC ``C:'a Form``
 >> STRIP_TAC
 >| [ RW_TAC std_ss [replaceRight, replaceRoot],
      MATCH_MP_TAC LextensionSimpl'
   >> STRIP_TAC
   >| [ ASM_REWRITE_TAC [],
	MATCH_MP_TAC CutRuleSimpl
     >> EXISTS_TAC ``(deltaTranslation (Comma (Comma (OneForm A) (OneForm B)) (OneForm C)))``
     >> RW_TAC std_ss [SeqAxiomGen, deltaTranslation_def] ] ]);

val NLPextensionSimpl = store_thm ("NLPextensionSimpl",
  ``!T1 T2 C E. extends NLP_Sequent E /\
		gentzenSequent E (Comma T1 T2) C
	    ==> gentzenSequent E (Comma T2 T1) C``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC SequentExtension
 >> EXISTS_TAC ``NLP_Sequent:'a gentzen_extension``
 >> EXISTS_TAC ``(Comma T1 T2)``
 >> EXISTS_TAC ``(Comma T1 T2)``
 >> EXISTS_TAC ``(Comma T2 T1)``
 >> RW_TAC std_ss [extends_def, RUNION, replaceRoot, NLP_Intro]);

val NLPextensionSimplDot = store_thm ("NLPextensionSimplDot",
  ``!A B C E. extends NLP_Sequent E /\
	      gentzenSequent E (OneForm (Dot A B)) C
	  ==> gentzenSequent E (OneForm (Dot B A)) C``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC LeftDotSimpl
 >> MATCH_MP_TAC NLPextensionSimpl
 >> STRIP_TAC
 >| [ ASM_REWRITE_TAC [],
      MATCH_MP_TAC CutRuleSimpl
   >> EXISTS_TAC ``(deltaTranslation (Comma (OneForm A) (OneForm B)))``
   >> RW_TAC std_ss [SeqAxiomGen, deltaTranslation_def] ]);

(* not needed for now
val mono_E = store_thm ("mono_E", (* original name: gentzenExtends, see also mono_X *)
  ``!E E'. extends E E' ==> (!Gamma A. gentzenSequent E Gamma A ==> gentzenSequent E' Gamma A)``,
    RW_TAC std_ss [extends_def, RSUBSET]
 >> PROVE_TAC [gentzenSequent_rules]
 >> );
 *)

(* Some theorems and derived properties
   These definitions can be applied for all gentzen extensions,
   we can see how CutRuleSimpl gets used in most of time. *)

val application = store_thm ("application",
  ``!A B E. gentzenSequent E (OneForm (Dot (Slash A B) B)) A``,
    PROVE_TAC [LeftDotSimpl, LeftSlashSimpl, SeqAxiom]);

val application' = store_thm ("application'",
  ``!A B E. gentzenSequent E (OneForm (Dot B (Backslash B A))) A``,
    PROVE_TAC [LeftDotSimpl, LeftBackslashSimpl, SeqAxiom]);

val RightSlashDot = store_thm ("RightSlashDot",
  ``!A B C E. gentzenSequent E (OneForm (Dot A C)) B ==> gentzenSequent E (OneForm A) (Slash B C)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightSlash
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(deltaTranslation (Comma (OneForm A) (OneForm C)))``
 >> RW_TAC std_ss [SeqAxiomGen, deltaTranslation_def]);

val coApplication = store_thm ("coApplication",
  ``!A B E. gentzenSequent E (OneForm A) (Slash (Dot A B) B)``,
    PROVE_TAC [RightSlash, RightDot, SeqAxiom]);

val coApplication' = store_thm ("coApplication'",
  ``!A B E. gentzenSequent E (OneForm A) (Backslash B (Dot B A))``,
    PROVE_TAC [RightBackslash, RightDot, SeqAxiom]);

val monotonicity = store_thm ("monotonicity",
  ``!A B C D E. gentzenSequent E (OneForm A) B /\
		gentzenSequent E (OneForm C) D
	    ==> gentzenSequent E (OneForm (Dot A C)) (Dot B D)``,
    PROVE_TAC [LeftDotSimpl, RightDot]);

val isotonicity = store_thm ("isotonicity",
  ``!A B C E. gentzenSequent E (OneForm A) B
	  ==> gentzenSequent E (OneForm (Slash A C)) (Slash B C)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightSlash
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``A:'a Form``
 >> PROVE_TAC [LeftSlashSimpl, SeqAxiom]);

val isotonicity' = store_thm ("isotonicity'",
  ``!A B C E. gentzenSequent E (OneForm A) B
	  ==> gentzenSequent E (OneForm (Backslash C A)) (Backslash C B)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightBackslash
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``A:'a Form``
 >> PROVE_TAC [LeftBackslashSimpl, SeqAxiom]);

val antitonicity = store_thm ("antitonicity",
  ``!A B C E. gentzenSequent E (OneForm A) B
	  ==> gentzenSequent E (OneForm (Slash C B)) (Slash C A)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightSlash
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot (Slash C B) B)``
 >> STRIP_TAC
 >| [ PROVE_TAC [RightDot, SeqAxiom],
      REWRITE_TAC [application] ]);

val antitonicity' = store_thm ("antitonicity'",
  ``!A B C E. gentzenSequent E (OneForm A) B
	  ==> gentzenSequent E (OneForm (Backslash B C)) (Backslash A C)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightBackslash
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot B (Backslash B C))``
 >> STRIP_TAC
 >| [ PROVE_TAC [RightDot, SeqAxiom],
      REWRITE_TAC [application'] ]);

val lifting = store_thm ("lifting",
  ``!A B C E. gentzenSequent E (OneForm A) (Slash B (Backslash A B))``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightSlash
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot A (Backslash A B))``
 >> STRIP_TAC
 >| [ PROVE_TAC [RightDot, SeqAxiom],
      REWRITE_TAC [application'] ]);

val lifting' = store_thm ("lifting'",
  ``!A B C E. gentzenSequent E (OneForm A) (Backslash (Slash B A) B)``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightBackslash
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot (Slash B A) A)``
 >> STRIP_TAC
 >| [ PROVE_TAC [RightDot, SeqAxiom],
      REWRITE_TAC [application] ]);

(* These definitions can be applied iff associativity is supported by our logical system *)

val mainGeach = store_thm ("mainGeach",
  ``!A B C E. extends L_Sequent E ==>
       gentzenSequent E (OneForm (Slash A B)) (Slash (Slash A C) (Slash B C))``,
    REPEAT STRIP_TAC
 >> NTAC 2 (MATCH_MP_TAC RightSlash)
 >> MATCH_MP_TAC LextensionSimpl
 >> STRIP_TAC THEN1 (POP_ASSUM ACCEPT_TAC)
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot (Slash A B) B)``
 >> STRIP_TAC
 >| [ MATCH_MP_TAC RightDot >> STRIP_TAC >|
      [ REWRITE_TAC [SeqAxiom],
        MATCH_MP_TAC LeftSlashSimpl >> STRIP_TAC >> REWRITE_TAC [SeqAxiom] ] ,
      REWRITE_TAC [application] ]);

val mainGeach' = store_thm ("mainGeach'",
  ``!A B C E. extends L_Sequent E ==>
       gentzenSequent E (OneForm (Backslash B A)) (Backslash (Backslash C B) (Backslash C A))``,
    REPEAT STRIP_TAC
 >> NTAC 2 (MATCH_MP_TAC RightBackslash)
 >> MATCH_MP_TAC LextensionSimpl'
 >> STRIP_TAC THEN1 (POP_ASSUM ACCEPT_TAC)
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot B (Backslash B A))``
 >> STRIP_TAC
 >| [ MATCH_MP_TAC RightDot >> STRIP_TAC >|
      [ MATCH_MP_TAC LeftBackslashSimpl >> STRIP_TAC >> REWRITE_TAC [SeqAxiom],
	REWRITE_TAC [SeqAxiom] ] ,
      REWRITE_TAC [application'] ]);

val secondaryGeach = store_thm ("secondaryGeach",
  ``!A B C E. extends L_Sequent E ==>
       gentzenSequent E (OneForm (Slash B C)) (Backslash (Slash A B) (Slash A C))``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightBackslash
 >> MATCH_MP_TAC RightSlash
 >> MATCH_MP_TAC LextensionSimpl
 >> STRIP_TAC THEN1 (POP_ASSUM ACCEPT_TAC)
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot (Slash A B) B)``
 >> STRIP_TAC
 >| [ MATCH_MP_TAC RightDot >> STRIP_TAC >|
      [ REWRITE_TAC [SeqAxiom],
	MATCH_MP_TAC LeftSlashSimpl >> STRIP_TAC >> REWRITE_TAC [SeqAxiom] ] ,
      REWRITE_TAC [application] ]);

val secondaryGeach' = store_thm ("secondaryGeach'",
  ``!A B C E. extends L_Sequent E ==>
       gentzenSequent E (OneForm (Backslash C B)) (Slash (Backslash C A) (Backslash B A))``,
    REPEAT STRIP_TAC
 >> MATCH_MP_TAC RightSlash
 >> MATCH_MP_TAC RightBackslash
 >> MATCH_MP_TAC LextensionSimpl'
 >> STRIP_TAC THEN1 (POP_ASSUM ACCEPT_TAC)
 >> MATCH_MP_TAC CutRuleSimpl
 >> EXISTS_TAC ``(Dot B (Backslash B A))``
 >> STRIP_TAC
 >| [ MATCH_MP_TAC RightDot >> STRIP_TAC >|
      [ MATCH_MP_TAC LeftBackslashSimpl >> STRIP_TAC >> REWRITE_TAC [SeqAxiom],
	REWRITE_TAC [SeqAxiom] ] ,
      REWRITE_TAC [application'] ]);




  
val _ = export_theory ();

(* last updated: January 8, 2016 *)

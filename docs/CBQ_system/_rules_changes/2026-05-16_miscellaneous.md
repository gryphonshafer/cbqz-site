# Miscellaneous Rules Changes

The following set of changes was implemented in [version 1.6 of the rule book](https://github.com/gryphonshafer/cbqz-site/commit/2c66aca) on Wednesday, May 14, 2026.

## Clarify Contested Verses

Translations make different choices about how to handle certain verses. Integrating multiple translations can sometimes present some interesting challenges regarding how each translation elected to include or exclude, merge or split up verse content. See [QuizSage’s translation integration documentation](https://quizsage.org/docs/translation_integration.md) for details.

In §1, the last sentence of the paragraph is changed to clarify included and excluded material with regard to how different translations handle these verses. The last sentence previously read:

> Any verse that does not exist as standard, non-footnote content across all included translations is excluded from the material.

Now it reads:

> Any verse where no portion thereof is included as standard inline, unbracketed, non-footnote content in any included translations is excluded from the material. Included verses will contain all inline content from their source translation, including content in parentheses or brackets, except for bracketed content with spans that begin or end mid-verse and continue unbroken into an excluded verse.

## Clarify Punctuation

In §2.5, content is added to explicitly clarify punctuation implications should be from the quizzer’s translation by adding the following to the end of the last paragraph:

> Should there be any punctuation differences between translations, the QM will use the punctuation from the translation on the quizzer’s registration to render a ruling.

This distinction matters when determining required response content to Phrase and Chapter queries where the quizzer’s registered translation includes sentence-ending punctuation after the prompt and before the end of the verse but the query’s source translation doesn’t.

## Eliminate Intentional Foul Incentive

Prior to the following rules edits, an edge case could exist where quizzers would be incentivized to intentionally foul on C queries in a 3-team quiz. A team could wait until the the prompt was fully read, then a quizzer triggers, and if that quizzer doesn’t immediately recognize and feel confident to respond correctly to the query, the quizzer could start speaking before their name is called. This would result in a foul, allowing an opportunity for the other quizzers on the team to attempt the same strategy.

The following 2 changes lightly patch this incentive:

- Eliminated the first bullet under §2.7 “Fouls” requiring a foul for speaking prior to the QM calling the quizzer’s name
- Added a “…following the QM calling the name of the quizzer” suffix clause to the second sentence in §2.1.4 “Response and Ruling”

In this way, quizzers will be incentivized to not speak until after their name is called to avoid having to repeat content; however, if they do speak before called, they won’t be fouled.

## Magistrate Discretion

There may be times when a QM must handle exceptional situations whose best solution the rules might otherwise preclude. For example, if quiz a quizzer on a team that has no timeout remaining feels suddenly ill and needs to take a break, the QM may believe the best solution would be to call a “general timeout” that’s not included explicitly in the rules. Thus, the following is added as §2.12:

> QMs may exercise discretion regarding the handling of circumstances unforeseen by these rules.

Also, the [Magistrate Best Practices](/tenants_and_essays/magistrate_best_practices.md) document is appended with additional clarity around best practices for handling these sorts of rare situations.

## Open Book Clarifications

In §2.3.2.3 for open book, there are 2 changes made for clarity:

- The phrase “brought with them to their chair” is changed to “brought to the row of quizzer's chairs either by the quizzer or by other seated quizzers with the intention they be shared”
- The phrase “in error” at the end of the last sentence is changed to “incorrect” to better align with the rest of the rule book phraseology

## Incentivize Reduction of Incorrect Responses

While the system already heavily disincentives incorrect responses by providing other teams additional points acquisition opportunities, some quizzers and coaches may not have fully embraced the scoring significance of these penalties and therefore do not modulate their trigger discipline appropriately. Some quizzers trigger too quickly to respond correctly, and despite being ruled incorrect, they don’t throttle back their speed, which puts them into a pattern of incorrect responses. This can result in quizzes with excess incorrect responses that feel cumbersome and burdensome to participants.

To both increase the incentive to avoid incorrect responses and cut back on this pattern of incorrect responses, the following sentence was inserted in the second paragraph of §2.2:

> Upon a quizzer’s second and each subsequent incorrect response, the quizzer will be ineligible to trigger for queries with the immediate next numerical component in their identifier.

(For clarity, the first sentence of the second paragraph of §2.2 has “and quizzers” inserted after “all teams”.)

*Both these changes are inserted in italic, meaning implementation while default enabled is nevertheless subject to regional discretion as per the [CBQ License](/governance/license.md).*

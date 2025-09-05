# Bible Distribution

The following set of changes was implemented in [version 1.5 of the rule book](https://github.com/gryphonshafer/cbqz-site/commit/afb599082582432d6693fe36cdd20d3c4922b9fd) on Monday, March 17, 2025.

## Present Settings and Proposed Alteration

Let’s start by defining the current rules, terminology I’ll use throughout this report, and then the rules changes and justification for them.

### Current Translation Distribution Rules

Translation distribution across queries in a quiz in a meet is defined in [CBQ Rule Book version 1.4.4](https://github.com/gryphonshafer/cbqz-site/blob/513fd114255e798811565abc32ab8edd84647e68/docs/CBQ_system/rule_book.md) in 2 locations:

1. In [section 2.4](https://github.com/gryphonshafer/cbqz-site/blob/513fd114255e798811565abc32ab8edd84647e68/docs/CBQ_system/rule_book.md#24-query-base-subtype-and-translation-distribution), which reads in part:

    > Each numerically identified query has a translation based on the randomized set of primary translations from a quiz’s material, then sequentially repeated.

2. And in [section 3.2](https://github.com/gryphonshafer/cbqz-site/blob/513fd114255e798811565abc32ab8edd84647e68/docs/CBQ_system/rule_book.md#32-materials), which reads in part:

    > The set of unique translations from all meet registrations will be the set of translations used for materials for every quiz in the meet.

### Terminology

- “Translation” — a Bible translation like NIV or ESV
- “Bible” — synonym for “translation”
- “Local” translation — the translation a quizzer memorized, relative to only that quizzer
- “Foreign” translation — any translation other than the local translation; again, relative to only that quizzer
- “Majority” translation — the translation that’s used by any >50% group of quizzers in a meet
- “Minority” translation — any translation that’s not a majority translation

### Suggested Change

In short, there was a suggestion that to reduce study demotivation we should switch translation distribution from uniform across the quizzes of a meet (based on the local translations of all quizzers registered for the meet) to a per quiz basis according to the quizzers in any given quiz. In other words, if of the quizzers in a quiz, there are 2 translations memorized, those 2 are used to build the distribution, but if all the quizzers are on a single translation, only that translation is used, despite other quizzers at the meet having memorized a different translation.

## Data Analysis

I conducted a series of deep dives of data analysis on real meet, quiz, and query data in [QuizSage](https://quizsage.org).

*(As an aside, if anyone would like to conduct their own analysis on this or any other topic, anyone with a QuizSage account can [download the 2 live/operations databases](https://quizsage.org/download). They are both [SQLite](https://www.sqlite.org) databases, which you can open and examine on any modern computer using free tools/libraries. (For the most common operating systems, you may consider [SQLite Browser](https://sqlitebrowser.org).) And if you’d like to re-run my analysis tools, I’ve published the software source code to the [QuizSage GitHub repository](https://github.com/gryphonshafer/quizsage/tree/master/tools/analysis). **In fact, I encourage those who are able to please re-run my analysis or at least take a look at the source code and review everything with skepticism.**)*

### Frequency of Issue

To establish a scope of the frequency of the issue, I looked at query rulings. I wanted to compare the posit case against a null or control case. While there are nearly 2 season’s worth of real meet-level query data in [QuizSage](https://quizsage.org), only the current Luke season provides both posit case and null case data of sufficient, cross-meet comparable quality.

In the [GEPC season of 2023-2024](https://quizsage.org/season/1/stats), all meets were NIV-only except [meet 4](https://quizsage.org/meet/2/stats). However, for that meet in particular, I made a tragic mistake setting up the material labels. I inadvertently inverted the club list weights so that in the Preliminary bracket questions from verses outside both club lists were overly represented, which resulted in significant quizzer score suppression. So unfortunately, I could only use the data from [the 4 meets from the Luke season](https://quizsage.org/season/3/stats). This amounts to 3,391 rulings across all rooms, all brackets, and all meets.

The situation posit 1 describes is where all 3 teams no trigger on a query due to the query being sourced from a foreign translation. To identity and isolate relevant case data, I needed to conduct a series of filters on the data to identify and isolate the subset of data that are prudent for case comparison. Some filters are obvious, but others are more subtle. Some obvious filters (including what I previously discussed):

- Luke season meet quiz queries with associated ruling data
- Queries with no trigger rulings
- Queries with a non-Quote base subtype (since Quote queries are translation-agnostic; they represent 25% of A queries in a quiz)

As to the more subtle filters: In particular, it’s important to remember that quizzers don’t memorize a verse to a Boolean state; that is to say, there isn’t a 2-state outcome of “not memorized” and “memorized”. Instead, a quizzer memorizes on a wide scale of quality, where 0% is not even having heard the verse before and 100% is accurate minimum key recognition with flawless verbatim with reference recall. A quizzer at 30% may be able to synonymously recite the verse correctly but may not be able to recognize it based on a local query prompt. A quizzer at 60% may be able to recognize most local prompts but not all.

As I’m sure any coach will attest to, many quizzers in the range of 20% to 50%, after a no trigger and upon hearing the full verse, will claim, “I knew that one.” And the quizzer is, in a sense, speaking truthfully. They did invest some time memorizing the verse, and now that the full verse text was recited, they recognize it and could if asked quote it synonymously, possibly even verbatim. However, they were never-the-less unable to identify the verse from a local prompt. Such quizzers tend to be in the middle or upper-middle of individual points scores lists, as this phenomenon occurs far less frequently when quizzers memorize fewer verses or when quizzers follow a disciplined memorization routine and thereby boost themselves above 60% memorization quality.

So to attempt to filter out events caused via this phenomenon, I looked for quizzer who had previously responded correctly to any query sourced from the same verse in any quiz or meet prior to the no trigger event. In other words, at some point in the past, the quizzer demonstrated they recognized at least some prompt for the verse in the past. This has a few problems, though. Quizzers who don’t review well (which unfortunately is prevalent behavior) will loose over time a portion of their ability to recognize a verse from a prompt, and this will artificially increase false positives in the data. And quizzers who don’t ever memorize a verse above a rate of perhaps 50% may not be able to successfully recognize a verse from mid-verse prompt, and this will artificially decrease true positives in the data.

Another consideration is to ensure that any quizzer who has shown via the data to “know the verse” (as defined by the filter) but is not eligible to trigger due to reaching their ceiling is not considered in terms of the analysis. And yet still, if there are other quizzers in the same quiz who “know the verse” and are eligible to trigger, the no trigger should still be included.

#### Filtered Data Summary

With these filters in place, there are 31 no trigger events to analyze from the 3,391 rulings. The following are the foreign versus local translation summaries:

- Source translations
    - 58% (18) are on queries sourced from foreign translations
    - 42% (13) are on queries sourced from local translations
- The verses in the data are from the following club lists:
    - Club 100 = 18 (58%)
    - Club 300 = 9 (29%)
    - Full Material = 4 (13%)
- The vast majority are from Preliminary brackets = 25 (81%)

#### Rough Conclusions

There are several reasons why an NIV quizzer who responded to a query sourced from a verse from the NIV in a previous query at some point in the past would fail to trigger on a query sourced from the same NIV verse later. These include the aforementioned insufficient review resulting in waning recognition ability, but it could also be for other factors including fatigue, distraction, or strategic (i.e. recognizing the verse and but not feeling confident to seek a VRA, and thus deciding not to trigger to save their eligibility for verses where they could VRA; however, this scenario is a bit unlikely in the cases with Club 100 verses or quizzers who don’t place within the top third of rankings). In all these cases, though, we can be certain that a local-versus-foreign translation confusion was not at play since the verses are sourced from local translations.

I think it’s reasonably safe to assume that for however many local translation queries are in the above report, there are a *roughly* equivalent number of foreign translation queries that are in the report for similar non-translation reasons. If this assumption is true, it means there perhaps about 5 no trigger events across 4 meets that resulted from foreign translation sourcing, or roughly 1.25 times per meet representing about 0.15% of rulings.

Another consideration to consider that’s not considered in any of the above analysis: There could be scenarios where a quizzer encounters a verse they know but no triggers, but that event happens prior to a later encounter with the same verse where they respond correctly. This outcomes delta could be due to some form of review between events, especially if the events are from different meets, or it could be for any of the reasons previously listed. This would occur for both local and foreign translation sourcing, but I would expect there to be a smaller delta between posit case and null case in this additional data due to there likely being at least some non-zero amount of total review investment between all such twin events.

### Power Law Analysis

I endeavored to construct a model that would predict a quizzer’s probability of scoring points in any given quiz independent of local/foreign translation sourcing. This would necessarily need to take into account the range of the material, the competition across a wide variety of draws, and the make-up of the team a quizzer sits on. If when run the model’s theoretical results approximated real outcomes for the population of quizzers across all meets, I may be able to leverage the model to predict some changes based on rules alterations.

I began this process with a simple power law model.

In most natural performance systems, outcomes aren’t evenly or normally distributed but instead follow a pattern where a small number of instances account for a disproportionately large share of the effect. This follows a power curve that could be expressed by `y = sx^k` where `x` is the input level (or rank), `s` is a scaling factor, and `k` is the power law exponent, which controls how steeply the distribution falls off. When we see statistically significant deviations occur from this model, this may signal systemic influences exist that adjust outcomes.

Like most natural performance systems, quizzer performance as defined by points earned if in a fair and systematically “clean” (or not unduly artificially influenced) way would tend to follow a power law curve. (Whereas by contrast, quizzer heights would tend to follow an evenly distributed or normally distributed curve.)

We can model this with the formula `P(x) = 1/(x+1)^k` where:

- `x` is the outcome modality, which in the case of CBQ quizzes is an integer between 0 and 31
- `P(x)` is the relative frequency, weight, or probability of `x` in the distribution
- `k` is the power law exponent

Once we derive the probability set (i.e. `P(x)`), we can collapse the probability distribution into a set of what I’ll call “model runs”. These are where instead of probabilities we end up with a set of actual scores that are predicted by the probability distribution.

After each run, we can adjust `k` and/or boost or deflate portions of the probability distribution to improve the model’s accuracy in predicting real data. We do this iteratively.

#### Matching Reality

To build a “reality set” of data, I looked at the nearly 2 seasons worth of historical statistics we have, and I calculated every quizzer’s per quiz individual points earned for all quizzes they participated in (including quizzes where the quizzer just sat). I then ran the model somewhere around 100,000 iterations to narrow in on the ideal `k` value and boost/deflate adjustments to approximate reality.

To best match, I isolated a `k` value of 1.55 and a pairing with an adjustment to the probabilities of modalities 28 through 31 up by a factor of 3. However, even without the adjustment, purely using a simple power law with a `k` of 1.55, the models approximated reality reasonably well across a merging of neighboring modalities. For example, if you average point modalities 1, 2, and 3 or 2, 3, and 4, or 13, 14, and 15, these moving averages track reality well. (This is similar to quantitative analysis of equity stock market symbol price data over a multi-day period, where to identify some technical analysis trends you have to remove random noise by calculating a moving average.)

*(Off topic but something to backburner for later deep thought: The adjustment to the probabilities of modalities 28 through 31 is an interesting finding and identifies a condition that seems to indicate a “bunching up” at the top end of the modalities distribution. This “bunching” was a larger factor during the GEPC season and a smaller factor in the Luke season, which correlates with increased top-end competition in the Luke season relative to the GEPC season. In smaller regions with outlier quizzers at the upper end of the spectrum, the CBQ rules system can still force a cap on points earning potential. As competition increases, this clumping to disappears. Still, it’s an important finding to note, because it may indicate a need to consider expanding the points range above 31 for the benefit of small regions with top-end outliers.)*

#### Rough Conclusions

I tried various ways to alter the distribution of reality by isolating seasons, meets, brackets, and quizzes on one axis whilst isolating local versus foreign translation, query type (base and quizzer-selected subtypes), and a variety of other factors. I wasn’t able to isolate any meaningful changes to the distribution regarding translation. What this means is that while difficulty may increase in responding to foreign translation queries relative to local (as identified and approximated via the frequency analysis above), both difficulty probability distributions remain consistent with natural power law.

*(An important caveat here: Models are models, not reality; which is to say, a model may model reality but it will never be reality, and models are always approximations at best. If we fail to apply persistent skepticism to models, they can easily distract us into believing the assumptions of models not coexistent with reality.)*

## Theoretical Analysis

Let’s start with the assumption that foreign translation queries are on average more difficult to recognize than local translation queries, even when all prompts are read out in full (as would be the case for no trigger events). The frequency data analysis seems to indicate this to be true, though to a small degree. But it seems reasonable to me to assume that as the length of the prompt read out shortens, the difficulty delta (the difference in difficulty of an equally shortened local versus remote query) increases.

*(For later analysis: I want to run a data analysis of several thousand generated queries, calculate recognition levels, and compare and contrast translations; however, that’s unnecessary for the purposes of this theoretical analysis.)*

As a region grows in strength, it seems reasonable to me to assume average prompt lengths read out in Preliminary brackets will shorten. Thus, as a region grows in strength, the difficulty of recognizing foreign translation prompts increases. This phenomenon parallels the difficulty recognizing local translation prompts, which also increases as a region grows in strength; however, the difficulty curve slope will exhibit a higher gradient for foreign translation prompts. Both slopes are somewhat de-inclined toward “weak region” levels through the use of secondary positional (i.e. “10-18”) and secondary score sum (i.e. “Auxiliary”) brackets.

### Theoretical Outcomes

With that all in mind, let’s compare (at a theoretical level) outcomes of the present settings versus the proposed alteration.

#### Present Settings

- All quizzers have an equal “foreign translation confusion” level in every quiz in a given meet.
    - The degree to which this is demotivational is difficult, perhaps impossible to accurately measure, but it seems reasonable to assume there would be a non-zero level of resulting demotivation.
    - But whatever this level of demotivation is, it’s consistent for all quizzers.
- No trigger events due to any foreign translation confusion are equal across all teams.
- Minority translation quizzers have “sloping slower” competition (i.e. as the region’s strength increases, prompts are triggered faster, and therefore the delta difficulty of pick up of foreign queries becomes higher relative to local) for local translation queries across a meet on average relative to majority translation quizzers.
    - A minority translation quizzer in a 2-teams-majority-versus-1-team-minority quiz will have a 2-query local recognition advantage.

#### Proposed Alteration

- Majority translation quizzers will experience a lower cumulative “foreign translation confusion” level across the whole of a meet.
    - Foreign translation confusion levels will vary for majority translation quizzers from quiz to quiz based on the participants within them (since some majority translation teams will face foreign translation teams and therefore experience quizzes with an even translation split in the distribution).
    - Majority translation quizzers will (in quizzes where no minority translations are represented) have a 6-query local recognition advantage over minority translation quizzers, which would impact:
        - Comparing individual scores across a meet for the purposes of meet individual placement and meet awards recognition
        - Sorting teams by score sum in Preliminary score sum brackets for qualification in Top 9 positional brackets
- Whatever demotivational effects the “foreign translation confusion” causes in the present settings would still exist for minority translation quizzers.
- No triggers due to any foreign translation confusion exist only when there are a mixture of translations in a quiz.
    - Majority translation quizzers who face fewer (or no) minority translation quizzers in a Preliminary bracket will have a score advantage over other majority translation quizzers.
    - This will result in the random draw assignments in low-quiz-count Preliminary brackets mattering more relative to the present settings, since if a team can face no foreign translation teams, they will have an advantage in terms of score sum versus teams that face a foreign translation team. (This is a non-factor in position brackets.)
- Minority translation quizzers still have “sloping slower” competition for local translation queries across a meet on average relative to majority translation quizzers (same as they do in the present settings).

#### Alternative: Proposed Alteration with Scores Boost by Foreign Translation Count

The idea here is that the propose alteration gets implemented, thus bifurcating quizzes into 2 groups: all queries from a single translation, and queries split evenly between translations represented by the participating quizzers. We can use the quiz’s positional results as we do normally, but in terms of individual and team scores, we adjust or boost the scores by a foreign translation count index factor.

So for example, let’s say there are 2 NIV teams A and B in a Preliminary bracket (though the example works for a positional bracket as well). Team A quizzes in 3 quizzes with all-NIV teams, and thus Team A only hears local translation queries. Team B quizzes in 3 quizzes where 1 of those quizzes included a non-NIV team. In the 1 quiz where Team B faces a non-NIV team, the translation distribution is evenly split between NIV and non-NIV. And so Team B would have their points (individual and team) boosted for that 1 quiz only by some auto-calculated factor.

The concern would then be in how to determine what that factor should be. One possible option is to compare all quizzers’ scores responding to local versus foreign translations in the given bracket, then take that delta as the factor. This would mean that the exact final factor wouldn’t be known until after a bracket concluded. However, it could be repeatedly calculated and implemented in real-time as the bracket progresses, so its progressing effects would be shown in the live statistics.

- Majority translation quizzers will experience a lower cumulative “foreign translation confusion” level across the whole of a meet.
- Whatever demotivational effects the “foreign translation confusion” causes in the present settings would still exist for minority translation quizzers.
- No triggers due to any foreign translation confusion exist only when there are a mixture of translations in a quiz.
- Comparing individual (and team) scores across a meet for the purposes of meet individual placement (and team placement outside of positional brackets) and meet awards recognition is brought back to fair.
    - Majority translation quizzers who face fewer (or no) minority translation quizzers in a Preliminary bracket will not have a meaningful score advantage over other majority translation quizzers.
- Random draw assignments in low-quiz-count Preliminary brackets won’t have a negative impact on scores and following bracket assignments.

Digging a bit into the details of this possible factor calculation: It would start with a factor of 1, and in the absence of any data/process described next, the factor would remain 1 (i.e. no boosting). Then, as quizzes complete, the calculation would consider all quizzers who faced foreign translation quizzers (both majority and minority, though the majority of these quizzers would be majority quizzers). Of the population of such quizzers, the quizzer’s point scores (excluding team bonus points) are collected into 2 buckets: scores from quizzes without foreign translation quizzers and scores from quizzes with foreign translation quizzers. Per quizzer, a factor variance between buckets gets calculated. Then all these factors are averaged to the final factor. This final factor is then applied to the individual and team scores for the meet. That is to say, it doesn’t back into the data from any quiz itself; rather, it’s applied at the meet statistics report layer (and optionally scores there could be presented both in “raw” versus “factor applied” for easy comparison).

Why should team bonus points in a quiz not be considered in factor calculation but the final factor should be applied to all point scores? Because the point of the factor is to approximate the difficulty difference between local and foreign prompt recognition. Team bonus points for sourcing will have a too-high noise to signal ratio because they are often based on what verses are specifically selected for following queries, especially in the case of follow-on bonuses.

A possible complication to this alternative is that prescribing the details of all this (especially the factor calculation algorithm) in the rule book concisely without causing confusion for most readers will be difficult. Implementing this in QuizSage will be relatively easy, though.

## Additional Considerations to Consider

When evaluating all the above, I plead with everyone to force yourself to frequently switch your point of view between majority and minority and between veteran, rookie, and prospective team organizations. If you coach a minority team, consider this all from a majority team’s perspective, and vise versa. If you coach a veteran organization, consider this all from rookie and prospective team organization points of view. It’s existentially critical we ensure Quizzing is engaging for all.

Consider also that PNW Quizzing is only mid-second season with CBQ, and so it’s important to look at the participation changes from the season just prior to season 1, compared to season 1, and compared to season 2 thus far, the growth of which happened with minimal systemic evangelism. Then extrapolate this out over 20 years of systemic evangelism, understanding that change happens in a curve, not a straight line.

Remember also that only 20% of Bible readers in the United States and Canada use the NIV, and that percentage is slowly shrinking. What is currently a majority translation will not necessarily remain so for the next 20 years.

And lastly, we’re seeing over the last 4 years a slow but rapidly increasing collapse of small Quizzing programs in various regions. CBQ can and is attracting some of the remnants. I feel it’s valuable to understand the reasons why many are considering CBQ, despite it being so small, new, and different.

## Rules Changes

The following are the rule change:

- 2.4. Query Base Subtype and Translation Distribution, third paragraph — *Replaced*
    > Each numerically identified query (except queries with the quote base subtype) has a translation based on the set of primary translations from a quiz’s material, filtered by the translations quizzers in each quiz use, then randomized, then sequentially repeated, skipping queries with the quote base subtype. For example, if a quiz’s material contains translations “A”, “B”, and “C” with quizzers in a particular quiz having memorized either “A” or “B” (but no quizzer in the particular having memorized “C”), the translations “A” and “B” are then randomized resulting in the sequence “BA”, which is then repeated for every query that doesn’t have the quote base subtype. In a 2-team quiz, the set of numerical identified queries may the translation sequence “BA\_BAB\_A” (where “\_” indicates no translation due to the query having the quote base subtype).
- 3.4. Score Weighting — *Replaced*

    > The meet director predefines weighting of quizzer and/or team scores based on bracket. For example, finals may be ignored for quizzer per quiz average score.
    >
    > In addition, should there be multiple primary translations at a meet where there are quizzes with only a single translation source for queries and other quizzes with multiple translation sources for queries, individual and team points scores used in meet statistics originating from quizzes with multiple translation sources for queries will be adjusted by a factor calculated as follows: For all quizzers in all quizzes at the meet who compete in both single and multiple translation sourced quizzes, the raw individual points earned by these quizzers will be averaged in groups by sourcing type (i.e. single or multiple). Then across all such quizzers, the 2 resulting type average sets will be each averaged, then the resulting 2 averages ratioed to a resultant factor.

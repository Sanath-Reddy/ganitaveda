import 'package:content_model/content_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:ganita_core/ganita_core.dart';
import 'package:ganitaveda/features/lesson/card_registry.dart';
import 'package:ganitaveda/shared/l10n.dart';

/// Steps through the classical method with the lesson's numbers, beside the
/// modern working (plan §4.6 card 4). On wide screens the two sit side by side.
class MethodCardView extends StatelessWidget {
  const new(this.c, {super.key});
  final CardContext c;

  @override
  Widget build(BuildContext context) {
    final card = c.card as MethodCard;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final runner = algorithms[card.algorithm];
    if (runner == null) return Center(child: Text(l.updateAppToSee));
    final Trace trace;
    try {
      trace = runner(card.inputs);
    } on Object {
      return Center(child: Text(l.somethingWrong));
    }
    final steps = trace.classical;
    final shown = ((c.state['shown'] as int?) ?? 1).clamp(1, steps.length);
    final wide = MediaQuery.sizeOf(context).width >= GVSpace.twoPaneBreakpoint;

    final classical = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.classicalMethod, style: t.labelLarge?.copyWith(color: GVColors.of(context).turmeric)),
        for (var i = 0; i < steps.length; i++)
          if (i < shown || wide)
            MethodStepTile(index: i + 1, text: context.lt(steps[i].text), working: steps[i].working, active: i < shown),
        const SizedBox(height: GVSpace.s),
        if (shown < steps.length)
          Wrap(
            spacing: GVSpace.s,
            children: [
              FilledButton.icon(
                onPressed: () => c.setState({...c.state, 'shown': shown + 1}),
                icon: const Icon(Icons.south),
                label: Text(l.nextStep),
              ),
              TextButton(onPressed: () => c.setState({...c.state, 'shown': steps.length}), child: Text(l.showAllSteps)),
            ],
          ),
      ],
    );
    final modernLines = [
      if (card.modern != null) context.lt(card.modern),
      for (final s in trace.modern) ...[if (context.lt(s.text).isNotEmpty) context.lt(s.text), ?s.working],
    ];
    final modern = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GVSpace.l),
      decoration: BoxDecoration(
        border: Border.all(color: GVColors.of(context).line),
        borderRadius: BorderRadius.circular(GVRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.modernWorking, style: t.labelLarge),
          const SizedBox(height: GVSpace.s),
          for (final line in modernLines)
            Padding(
              padding: const EdgeInsets.only(bottom: GVSpace.xs),
              child: Text(line, style: t.bodyLarge?.copyWith(color: GVColors.of(context).indigo)),
            ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(GVSpace.gutter, GVSpace.l, GVSpace.gutter, GVSpace.xxl),
      children: [
        Text(context.lt(card.intro), style: t.bodyLarge),
        const SizedBox(height: GVSpace.l),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: classical),
              const SizedBox(width: GVSpace.xl),
              Expanded(flex: 2, child: modern),
            ],
          )
        else ...[
          classical,
          const SizedBox(height: GVSpace.l),
          if (shown >= steps.length) modern,
        ],
      ],
    );
  }
}

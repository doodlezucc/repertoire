import 'package:flutter/material.dart';

int score(String s, String actual) {
  if (actual.startsWith(s)) return 2;
  if (actual.contains(' $s')) return 1;

  return 0;
}

AutocompleteOptionsBuilder<String> containMatcher(Iterable<String> all) {
  final map = Map<String, String>.fromEntries(
      all.map((s) => MapEntry(s, s.toLowerCase())));

  return ((textEditingValue) {
    if (textEditingValue.text.isEmpty) return Iterable.empty();

    var text = textEditingValue.text.toLowerCase();
    var possible = map.keys.where((s) => map[s]!.contains(text)).toList();
    possible.sort((c, d) {
      var a = map[c]!;
      var b = map[d]!;

      var diff = score(text, b) - score(text, a);

      if (diff == 0) return b.compareTo(a);

      return diff;
    });
    return possible;
  });
}

class AutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final AutocompleteOptionsBuilder<String> optionsBuilder;
  final AutocompleteOnSelected<String>? onSelected;
  final FocusNode focusNode;
  final String hintText;
  final void Function(String)? onChanged;

  const AutocompleteField({
    Key? key,
    required this.optionsBuilder,
    required this.focusNode,
    required this.controller,
    this.onChanged,
    this.hintText = '',
    this.onSelected,
  }) : super(key: key);

  @override
  State<AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<AutocompleteField> {
  String query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(onControllerInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(onControllerInput);
    super.dispose();
  }

  void onControllerInput() {
    setState(() => query = widget.controller.text);
  }

  Widget optionsViewBuilder(
    BuildContext context,
    AutocompleteOnSelected<String> onSelected,
    Iterable<String> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            shrinkWrap: true,
            itemBuilder: (ctx, index) => AutocompleteSuggestion(
              text: options.elementAt(index),
              query: query,
              onTap: () => onSelected(options.elementAt(index)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete(
      textEditingController: widget.controller,
      focusNode: widget.focusNode,
      optionsViewBuilder: optionsViewBuilder,
      optionsBuilder: widget.optionsBuilder,
      onSelected: (String s) {
        print(widget.focusNode.hasFocus);
        if (widget.onSelected != null) {
          print('ON SELECTED $s');
          widget.onSelected!(s);
        }
      },
      fieldViewBuilder:
          (ctx, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          onChanged: widget.onChanged,
          focusNode: focusNode,
          controller: textEditingController,
          decoration: InputDecoration(hintText: widget.hintText),
        );
      },
    );
  }
}

class AutocompleteSuggestion extends StatelessWidget {
  final String text;
  final String query;
  final void Function() onTap;

  const AutocompleteSuggestion({
    Key? key,
    required this.text,
    required this.query,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final start = text.toLowerCase().indexOf(query.toLowerCase());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyText2,
            children: [
              TextSpan(text: text.substring(0, start)),
              TextSpan(
                text: text.substring(start, start + query.length),
                style: TextStyle(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withAlpha(80)),
              ),
              TextSpan(text: text.substring(start + query.length)),
            ],
          ),
        ),
      ),
    );
  }
}

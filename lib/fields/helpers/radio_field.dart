import 'package:every_door/constants.dart';
import 'package:flutter/material.dart';

class RadioField extends StatefulWidget {
  final List<String> options;
  final List<String>? labels;
  final String? value;
  final Function(String?) onChange;

  const RadioField(
      {required this.options, this.labels, this.value, required this.onChange});

  @override
  _RadioFieldState createState() => _RadioFieldState();
}

class _RadioFieldState extends State<RadioField> {
  @override
  Widget build(BuildContext context) {
    String? labelForValue;
    if (widget.value != null && widget.labels != null) {
      int idx = widget.options.indexOf(widget.value!);
      if (idx >= 0 && idx < widget.labels!.length)
        labelForValue = widget.labels![idx];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      // TODO: Wrap instead? Only when > 5 options?
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (widget.value != null)
              RadioPill(
                value: widget.value!,
                label: labelForValue,
                selected: true,
                onTap: () {
                  widget.onChange(null);
                },
              ),
            for (final entry in widget.options.asMap().entries)
              if (entry.value != widget.value)
                RadioPill(
                  value: entry.value,
                  label:
                      widget.labels != null && widget.labels!.length > entry.key
                          ? widget.labels![entry.key]
                          : null,
                  selected: false,
                  onTap: () {
                    widget.onChange(entry.value);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class RadioPill extends StatelessWidget {
  final String value;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  const RadioPill(
      {required this.value,
      this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: GestureDetector(
        child: Container(
          height: kFieldFontSize + 18.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).primaryColor : null,
            border: Border.all(),
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
          child: Text(
            label ?? value,
            style: kFieldTextStyle.copyWith(
              color:
                  selected ? Theme.of(context).selectedRowColor : Colors.black,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

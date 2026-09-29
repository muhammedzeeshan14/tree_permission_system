import 'package:flutter/material.dart';

/// Keeps desktop rows, but gives each form/control its own line on phones.
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double breakpoint, spacing;
  const AdaptiveRow({super.key, required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.breakpoint = 600, this.spacing = 10});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (!constraints.hasBoundedWidth || constraints.maxWidth >= breakpoint * scale) {
      return Row(mainAxisAlignment:mainAxisAlignment,
        crossAxisAlignment:crossAxisAlignment, mainAxisSize:mainAxisSize, children:children);
    }
    final items = <Widget>[];
    for (var child in children) {
      if (child is Spacer) continue;
      if (child is Flexible) child = child.child;
      if (child is SizedBox) {
        if (child.child == null) continue;
        // A desktop label/control width must not constrain the phone column.
        if (child.width != null) child = SizedBox(height:child.height, child:child.child);
      }
      items.add(child);
    }
    return Column(mainAxisSize:MainAxisSize.min,
      crossAxisAlignment:CrossAxisAlignment.stretch,
      children:[for(var i=0;i<items.length;i++) ...[
        if(i>0) SizedBox(height:spacing), items[i],
      ]]);
  });
}

/// Keeps navigation accessible above system bars and scrollable in short viewports.
class NavigationPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const NavigationPanel({super.key, required this.child,
    this.padding = const EdgeInsets.all(15)});
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = (media.size.height - media.viewInsets.bottom - media.padding.vertical)
        .clamp(120.0, double.infinity);
    return SafeArea(top:false, child:ConstrainedBox(
      constraints:BoxConstraints(maxHeight:available * .4),
      child:SingleChildScrollView(child:Padding(padding:padding,child:child)),
    ));
  }
}

/// Document title stays readable; actions move below it on narrow screens.
class AdaptiveDocumentTile extends StatelessWidget {
  final Widget? leading, subtitle, trailing;
  final Widget title;
  final VoidCallback? onTap;
  const AdaptiveDocumentTile({super.key, this.leading, required this.title,
    this.subtitle, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder:(context,c) {
    if(c.maxWidth >= 640 * MediaQuery.textScalerOf(context).scale(14)/14) {
      return ListTile(leading:leading,title:title,subtitle:subtitle,trailing:trailing,onTap:onTap);
    }
    return InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.all(12),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(leading!=null) ...[leading!,const SizedBox(width:10)],
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[title,if(subtitle!=null) ...[const SizedBox(height:6),subtitle!]])),
        ]),
        if(trailing!=null) ...[const SizedBox(height:12),trailing!],
      ]),
    ));
  });
}

class TimeEntryLayout extends StatelessWidget {
  final Widget title, hour, minute, period;
  const TimeEntryLayout({super.key, required this.title, required this.hour,
    required this.minute, required this.period});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder:(context,c) {
    final clock = Row(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Expanded(child:hour), const Padding(padding:EdgeInsets.all(12),child:Text(':')),
      Expanded(child:minute),
    ]);
    if(c.maxWidth < 600 * MediaQuery.textScalerOf(context).scale(14)/14) {
      return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        title,const SizedBox(height:12),clock,const SizedBox(height:12),period,
      ]);
    }
    return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      SizedBox(width:150,child:title),Expanded(child:clock),
      const SizedBox(width:12),SizedBox(width:110,child:period),
    ]);
  });
}

/// Preserve readable table column widths instead of compressing them on phones.
class ScrollableTableViewport extends StatelessWidget {
  final Widget child;
  final double minWidth;
  const ScrollableTableViewport({super.key,required this.child,this.minWidth=1100});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder:(context,c) {
    final width = (minWidth * MediaQuery.textScalerOf(context).scale(14)/14)
        .clamp(c.maxWidth,double.infinity);
    return SingleChildScrollView(scrollDirection:Axis.horizontal,
      child:SizedBox(width:width,height:c.hasBoundedHeight?c.maxHeight:null,child:child));
  });
}

/// Long applicant details remain readable without displacing the form/navigation.
class ResponsiveHeader extends StatelessWidget {
  final Widget child;
  const ResponsiveHeader({super.key,required this.child});
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if(media.size.width >= 800 && media.size.height >= 600) return child;
    final available = (media.size.height-media.viewInsets.bottom-media.padding.vertical)
        .clamp(120.0,double.infinity);
    return ConstrainedBox(constraints:BoxConstraints(maxHeight:available*.25),
      child:SingleChildScrollView(child:child));
  }
}

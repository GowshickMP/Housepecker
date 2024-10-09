import 'package:Housepecker/Ui/screens/home/Widgets/property_horizontal_card.dart';
import 'package:Housepecker/Ui/screens/widgets/AnimatedRoutes/blur_page_route.dart';
import 'package:Housepecker/Ui/screens/widgets/Erros/something_went_wrong.dart';
import 'package:Housepecker/utils/Extensions/extensions.dart';
import 'package:Housepecker/utils/helper_utils.dart';
import 'package:Housepecker/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../data/model/property_model.dart';

///In this file https://dart.dev/language/generics generic types are used For more info you can see this

///This [PropertySuccessStateWireframe] this will force class to have properties list

abstract class PropertySuccessStateWireframe {
  abstract List<PropertyModel> properties;
  abstract bool isLoadingMore;
}

///this will force class to have error field
abstract class PropertyErrorStateWireframe {
  dynamic error;
}

///This implementation is for cubit this will force property cubit to implement this methods.
abstract class PropertyCubitWireframe {
  void fetch();
  bool hasMoreData();
  void fetchMore();
}

class ViewAllScreen<T extends StateStreamable<C>, C> extends StatefulWidget {
  final String title;
  final StateMap map;
  ViewAllScreen({
    Key? key,
    required this.title,
    required this.map,
  }) : super(key: key) {
    assert(T is! PropertyErrorStateWireframe,
        "Please Extend PropertyErrorStateWireframe in cubit");
  }

  void open(BuildContext context) {
    Navigator.push(context, BlurredRouter(
      builder: (context) {
        return ViewAllScreen<T, C>(title: title, map: map);
      },
    ));
  }

  @override
  _ViewAllScreenState<T, C> createState() => _ViewAllScreenState<T, C>();
}

class _ViewAllScreenState<T extends StateStreamable<C>, C>
    extends State<ViewAllScreen> {
  final ScrollController _pageScrollListener = ScrollController();

  @override
  void initState() {
    _pageScrollListener.addListener(onPageEnd);

    super.initState();
  }

  @override
  void dispose() {
    _pageScrollListener.dispose();
    super.dispose();
  }

  bool isSubtype<S, T>() => <S>[] is List<T>;
  void onPageEnd() {
    ///This is extension which will check if we reached end or not
    if (_pageScrollListener.isEndReached()) {
      if (isSubtype<T, PropertyCubitWireframe>()) {
        if (read<T>().hasMoreData()) {
          read<T>().fetchMore();
        }
      }
    }
  }

  dynamic read<X>() {
    return context.read<X>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: context.color.secondaryColor,
      //   elevation: 0,
      //   iconTheme: IconThemeData(color: context.color.teritoryColor),
      //   title: Text(
      //     widget.title,
      //   ).color(context.color.teritoryColor).size(context.font.large),
      // ),
      appBar: UiUtils.buildAppBar(context,
          title: widget.title, showBackButton: true),
// body: Container(),
      body: BlocBuilder<T, C>(builder: (context, state) {
        return widget.map._buildState(state, _pageScrollListener);
      }),
    );
  }
}

///From generic type we are getting state so we can return ui according to that state
class StateMap<INITIAL, PROGRESS, SUCCESS extends PropertySuccessStateWireframe,
    FAIL extends PropertyErrorStateWireframe> {
  Widget _buildState(dynamic state, ScrollController controller) {
    if (state is INITIAL) {
      return Container();
    }
    if (state is PROGRESS) {
      return Center(child: UiUtils.progress());
    }
    if (state is FAIL) {
      return const SomethingWentWrong();
    }

    if (state is SUCCESS) {
      return Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: RemoveGlow(),
              child: GridView.builder(
                  padding: const EdgeInsets.all(15),
                   controller: controller,
                  shrinkWrap: true,
                 itemCount: state.properties.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1 / 1.2,
                  ),
         
                  itemBuilder: (context, index) {
                    PropertyModel model = state.properties[index];
                     return GestureDetector(
                      onTap: () {
                        HelperUtils.goToNextPage(
                          Routes.propertyDetails,
                          context,
                          false,
                          args: {
                            'propertyData': model,
                            'propertiesList': state.properties,
                            'fromMyProperty': false,
                          },
                        );
                      },
                      child: PropertyHorizontalCard(property: model));
                  },
                ),
            ),
          ),
          if (state.isLoadingMore) UiUtils.progress()
        ],
      );
    }

    return Container();
  }
}

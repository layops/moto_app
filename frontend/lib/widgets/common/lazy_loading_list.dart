import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LazyLoadingList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) dataFetcher;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? emptyWidget;
  final Widget Function(BuildContext context)? loadingWidget;
  final Widget Function(BuildContext context)? errorWidget;
  final int pageSize;
  final bool hasMore;
  final String? errorMessage;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;

  const LazyLoadingList({
    super.key,
    required this.dataFetcher,
    required this.itemBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.pageSize = 20,
    this.hasMore = true,
    this.errorMessage,
    this.padding,
    this.scrollController,
  });

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (refresh) {
        _items.clear();
        _currentPage = 1;
      }
    });

    try {
      final newItems = await widget.dataFetcher(_currentPage, widget.pageSize);
      
      if (mounted) {
        setState(() {
          if (refresh) {
            _items.clear();
          }
          _items.addAll(newItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !widget.hasMore) return;

    setState(() {
      _currentPage++;
    });

    await _loadData();
  }

  Future<void> refresh() async {
    await _loadData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget?.call(context) ?? _buildErrorWidget();
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget?.call(context) ?? _buildLoadingWidget();
    }

    if (_items.isEmpty) {
      return widget.emptyWidget?.call(context) ?? _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: widget.scrollController ?? _scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Yükleniyor...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16.h),
          Text(
            widget.errorMessage ?? 'Bir hata oluştu',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => _loadData(refresh: true),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.w,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16.h),
          Text(
            'Henüz veri yok',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class LazyLoadingGrid<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) dataFetcher;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? emptyWidget;
  final Widget Function(BuildContext context)? loadingWidget;
  final Widget Function(BuildContext context)? errorWidget;
  final int pageSize;
  final bool hasMore;
  final String? errorMessage;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const LazyLoadingGrid({
    super.key,
    required this.dataFetcher,
    required this.itemBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.pageSize = 20,
    this.hasMore = true,
    this.errorMessage,
    this.padding,
    this.scrollController,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  });

  @override
  State<LazyLoadingGrid<T>> createState() => _LazyLoadingGridState<T>();
}

class _LazyLoadingGridState<T> extends State<LazyLoadingGrid<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (refresh) {
        _items.clear();
        _currentPage = 1;
      }
    });

    try {
      final newItems = await widget.dataFetcher(_currentPage, widget.pageSize);
      
      if (mounted) {
        setState(() {
          if (refresh) {
            _items.clear();
          }
          _items.addAll(newItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !widget.hasMore) return;

    setState(() {
      _currentPage++;
    });

    await _loadData();
  }

  Future<void> refresh() async {
    await _loadData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget?.call(context) ?? _buildErrorWidget();
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget?.call(context) ?? _buildLoadingWidget();
    }

    if (_items.isEmpty) {
      return widget.emptyWidget?.call(context) ?? _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: GridView.builder(
        controller: widget.scrollController ?? _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.childAspectRatio,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
        ),
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Yükleniyor...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16.h),
          Text(
            widget.errorMessage ?? 'Bir hata oluştu',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => _loadData(refresh: true),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.w,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16.h),
          Text(
            'Henüz veri yok',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

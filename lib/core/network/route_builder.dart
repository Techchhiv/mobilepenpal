class RouteBuilder {
  static String build(String route, Map<String, String> params) {
    var path = route;
    params.forEach((key, value) {
      path = path.replaceFirst(':$key', value);
    });
    return path;
  }
}

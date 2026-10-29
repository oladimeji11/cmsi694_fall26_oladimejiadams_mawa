/// Represents an active weather alert issued by the National Weather Service (NWS).
class WeatherAlert {
  final String event;
  final String severity;
  final String areaDesc;
  final DateTime? expires;
  final String? headline;

  const WeatherAlert({
    required this.event,
    required this.severity,
    required this.areaDesc,
    this.expires,
    this.headline,
  });

  /// Factory constructor to parse NWS active alert feature JSON properties.
  factory WeatherAlert.fromNwsJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};

    DateTime? parsedExpires;
    final expiresStr = properties['expires'] as String?;
    if (expiresStr != null) {
      parsedExpires = DateTime.tryParse(expiresStr);
    }

    return WeatherAlert(
      event: (properties['event'] as String?) ?? 'Weather Alert',
      severity: (properties['severity'] as String?) ?? 'Moderate',
      areaDesc: (properties['areaDesc'] as String?) ?? 'Local Area',
      expires: parsedExpires,
      headline: properties['headline'] as String?,
    );
  }
}

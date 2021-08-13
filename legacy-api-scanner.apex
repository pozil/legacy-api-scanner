/*
 * Scans for legacy SOAP, REST or Bulk API calls as defined here: https://help.salesforce.com/articleView?id=000351312&type=1&mode=1&language=en_US
 * Project repository: https://github.com/pozil/legacy-api-scanner
 */
void scanForLegacyApis() {
  // Get EventLogFile records with EventType = 'ApiTotalUsage'
  Integer logCount = Database.countQuery('SELECT COUNT() FROM EventLogFile WHERE EventType = \'ApiTotalUsage\'');
  if (logCount == 0) {
    System.debug('Found no EventLogFile entry of type ApiTotalUsage.');
    System.debug('This indicates that no legacy APIs were called during the log retention window.');
    return;
  }

  System.debug('Found ' + logCount + ' ApiTotalUsage EventLogFile entries.');
  // Warning if too many log entries
  if (logCount > 99) {
    System.debug('WARNING: Because of Apex/SOQL limits, we can only parse the first 99 entries.');
  }

  // Get log files one by one to avoid heap size limit errors
  Set<String> legacyApiVersions = new Set<String>();
  for (Integer logIndex = 0; logIndex<99; logIndex++) {
    EventLogFile logFile = [SELECT LogFile FROM EventLogFile WHERE EventType = 'ApiTotalUsage' ORDER BY CreatedDate LIMIT 1 OFFSET :logIndex];
    // Parse CSV from log file
    String logCsv = logFile.LogFile.toString();
    List<List<String>> logRows = parseCsvFile(logCsv);
    legacyApiVersions.addAll(getUniqueApiVersions(logRows));
  }

  // Report legacy API calls
  System.debug('Found legacy API versions in logs: ' + legacyApiVersions);
}

List<List<String>> parseCsvFile(String csvString) {
  List<List<String>> data = new List<List<String>>();
  List<String> rows = safeSplit(csvString, '\n');
  for (String row : rows) {
    List<String> cells = safeSplit(row, ',');
    for (Integer i = 0; i < cells.size(); i++) {
      cells[i] = cells[i].substring(1, cells[i].length() - 1);
    }
    data.add(cells);
  }
  return data;
}

Set<String> getUniqueApiVersions(List<List<String>> data) {
  Integer apiFamilyColIndex = getColIndexFromLabel(data, 'API_FAMILY');
  Integer apiVersionColIndex = getColIndexFromLabel(data, 'API_VERSION');

  Set<String> uniqueApiVersions = new Set<String>();
  for (Integer i = 1; i < data.size(); i++) {
    String apiVersion = data[i][apiFamilyColIndex] + ' v' + data[i][apiVersionColIndex];
    uniqueApiVersions.add(apiVersion);
  }
  return uniqueApiVersions;
}

Integer getColIndexFromLabel(List<List<String>> data, String colLabel) {
  Integer index = data[0].indexOf(colLabel);
  if (index == -1) {
    throw new ScanException('Could not find ' + colLabel + ' column');
  }
  return index;
}

/**
 * Using this custom split method instead of String.split() to handle
 * large volumes of text and avoid Regex limit errors
 */
List<String> safeSplit(String content, String separator) {
  List<String> parts = new List<String>();
  Integer contentLength = content.length();
  Integer separatorLength = separator.length();
  Integer startIndex = 0;
  Integer foundIndex = 0;
  while (foundIndex != -1 && startIndex != contentLength) {
    foundIndex = content.indexOf(separator, startIndex);
    if (foundIndex == -1) {
      parts.add(content.substring(startIndex));
    } else {
      parts.add(content.substring(startIndex, foundIndex));
      startIndex = foundIndex + separatorLength;
    }
  }
  return parts;
}

class ScanException extends Exception {
}

// Start the scan
scanForLegacyApis();

public with sharing class LegacyApiScanner {
  public void scan() {
    // Get EventLogFile records with EventType = 'ApiTotalUsage'
    List<EventLogFile> logFiles = [
      SELECT LogFile
      FROM EventLogFile
      WHERE EventType = 'ApiTotalUsage'
    ];
    if (logFiles.size() == 0) {
      System.debug('Found no EventLogFile entry of type ApiTotalUsage.');
      System.debug(
        'This indicates that no legacy APIs were called during the log retention window.'
      );
      return;
    }

    // Parse CSV from log files
    System.debug(
      'Parsing ' +
      logFiles.size() +
      ' ApiTotalUsage EventLogFile entries...'
    );
    Set<String> legacyApiVersions = new Set<String>();
    for (EventLogFile logFile : logFiles) {
      String logCsv = logFile.LogFile.toString();
      List<List<String>> logRows = parseCsvFile(logCsv);
      legacyApiVersions.addAll(getUniqueApiVersions(logRows));
    }
    // Report legacy API calls
    System.debug('Found legacy API versions in logs: ' + legacyApiVersions);
  }

  private Set<String> getUniqueApiVersions(List<List<String>> data) {
    Integer apiFamilyColIndex = getColIndexFromLabel(data, 'API_FAMILY');
    Integer apiVersionColIndex = getColIndexFromLabel(data, 'API_VERSION');

    Set<String> uniqueApiVersions = new Set<String>();
    for (Integer i = 1; i < data.size(); i++) {
      String apiVersion =
        data[i][apiFamilyColIndex] +
        ' v' +
        data[i][apiVersionColIndex];
      uniqueApiVersions.add(apiVersion);
    }
    return uniqueApiVersions;
  }

  private List<List<String>> parseCsvFile(String csvString) {
    List<List<String>> data = new List<List<String>>();
    List<String> rows = csvString.split('\n');
    for (String row : rows) {
      List<String> cells = row.split(',');
      for (Integer i = 0; i < cells.size(); i++) {
        cells[i] = cells[i].substring(1, cells[i].length() - 1);
      }
      data.add(cells);
    }
    return data;
  }

  private Integer getColIndexFromLabel(
    List<List<String>> data,
    String colLabel
  ) {
    Integer index = data[0].indexOf(colLabel);
    if (index == -1) {
      throw new ScanException('Could not find ' + colLabel + ' column');
    }
    return index;
  }

  private class ScanException extends Exception {
  }
}

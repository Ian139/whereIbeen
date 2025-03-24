import Foundation

/// Handles loading and parsing data from files
class DataLoader {
    /// Shared instance for singleton access
    static let shared = DataLoader()
    
    /// Load data from a CSV file
    /// - Parameter fileName: Name of the CSV file without extension
    /// - Returns: String contents of the file, or nil if the file couldn't be loaded
    func loadCSV(fileName: String) -> String? {
        // First try to load from the app bundle
        if let path = Bundle.main.path(forResource: fileName, ofType: "csv") {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                return content
            } catch {
                print("Failed to load \(fileName).csv from bundle: \(error)")
            }
        }
        
        // Fallback to Documents directory
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent("\(fileName).csv")
        
        do {
            let content = try String(contentsOf: destinationUrl, encoding: .utf8)
            return content
        } catch {
            print("Failed to load \(fileName).csv: \(error)")
            
            // If it's the default file, provide basic empty structure
            if fileName == "default" {
                return "id,name,date,lat,long\n"
            }
            
            return nil
        }
    }
    
    /// Parse CSV data into an array of dictionaries
    /// - Parameter data: CSV string data
    /// - Returns: Array of dictionaries with column headers as keys
    func parseCSV(data: String) -> [[String: String]] {
        var result: [[String: String]] = []
        
        let rows = data.components(separatedBy: "\n")
        guard !rows.isEmpty else { return [] }
        
        // Get headers from first row
        let headers = rows[0].components(separatedBy: ",")
        guard !headers.isEmpty else { return [] }
        
        // Process data rows
        for i in 1..<rows.count {
            let row = rows[i]
            if row.isEmpty { continue }
            
            let columns = row.components(separatedBy: ",")
            var rowDict: [String: String] = [:]
            
            for (index, header) in headers.enumerated() {
                if index < columns.count {
                    rowDict[header] = columns[index]
                }
            }
            
            if !rowDict.isEmpty {
                result.append(rowDict)
            }
        }
        
        return result
    }
} 
import Foundation

enum SupabaseConfig {
    static let url = URL(string: "https://tvzfyptiouihtitlapcv.supabase.co")!
    static let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2emZ5cHRpb3VpaHRpdGxhcGN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2OTI3NTAsImV4cCI6MjA4OTI2ODc1MH0.f-WZVWNaXYOcyIHm8XrI8ZXFzeAhGm1Oyl2-k_Dv79g"
    static let storageBaseURL = url.appendingPathComponent("storage/v1/object/public/bike-images/")
}

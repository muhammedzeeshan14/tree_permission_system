// Default Kannada names for master entries (seed + backfill).
// Key: "masterType|value" or "Section|...", "Beat|...".
class MasterKannada {
  MasterKannada._();

  static const Map<String, String> names = {
    // Sections
    'Section|Mysuru Urban': 'ಮೈಸೂರು ನಗರ',
    'Section|Mysuru Rural': 'ಮೈಸೂರು ಗ್ರಾಮಾಂತರ',
    'Section|Mysuru South': 'ಮೈಸೂರು ದಕ್ಷಿಣ',
    // Beats
    'Beat|Nazarbad': 'ನಜರಬಾದ್',
    'Beat|Siddarthanagar': 'ಸಿದ್ಧಾರ್ಥನಗರ',
    'Beat|Chamundi': 'ಚಾಮುಂಡಿ',
    'Beat|Yelwala': 'ಯಳವಳ',
    // Government Agency
    'Government Agency|Forest Department': 'ಅರಣ್ಯ ಇಲಾಖೆ',
    'Government Agency|Revenue Department': 'ಕಂದಾಯ ಇಲಾಖೆ',
    'Government Agency|Public Works Department':
        'ಲೋಕೋಪಯೋಗಿ ಇಲಾಖೆ',
    // Urban Rural
    'Urban Rural|Urban': 'ನಗರ',
    'Urban Rural|Rural': 'ಗ್ರಾಮಾಂತರ',
    'Urban Rural|Semi-Urban': 'ಅರೆ ನಗರ',
    // Structure Type
    'Structure Type|Building': 'ಕಟ್ಟಡ',
    'Structure Type|Road': 'ರಸ್ತೆ',
    'Structure Type|Layout': 'ಬಡಾವಣೆ',
    // Tree Status
    'Tree Status|Healthy': 'ಆರೋಗ್ಯಕರ',
    'Tree Status|Dead': 'ಸತ್ತ',
    'Tree Status|Dangerous': 'ಅಪಾಯಕಾರಿ',
    'Tree Status|Diseased': 'ರೋಗಪೀಡಿತ',
    // Inspecting Officer Overall Remark
    'Inspecting Officer Overall Remark|Recommended':
        'ಶಿಫಾರಸು ಮಾಡಲಾಗಿದೆ',
    'Inspecting Officer Overall Remark|Not Recommended':
        'ಶಿಫಾರಸು ಮಾಡಲಾಗಿಲ್ಲ',
    'Inspecting Officer Overall Remark|Need Re-inspection':
        'ಮರು ಪರಿಶೀಲನೆ ಅಗತ್ಯ',
    // Mahazar Location
    'Mahazar Location|East': 'ಪೂರ್ವ',
    'Mahazar Location|West': 'ಪಶ್ಚಿಮ',
    'Mahazar Location|North': 'ಉತ್ತರ',
    'Mahazar Location|South': 'ದಕ್ಷಿಣ',
    // Purpose
    'Purpose|House Construction': 'ಮನೆ ನಿರ್ಮಾಣ',
    'Purpose|Agriculture': 'ಕೃಷಿ',
    'Purpose|Road Widening': 'ರಸ್ತೆ ಅಗಲೀಕರಣ',
    // Problem
    'Problem|Dangerous': 'ಅಪಾಯಕಾರಿ',
    'Problem|Dead': 'ಸತ್ತ',
    'Problem|Dry': 'ಒಣಗಿದ',
    // Species
    'Species|Neem': 'ಬೇವು',
    'Species|Honge': 'ಹೊಂಗೆ',
    'Species|Teak': 'ತೇಗ',
    'Species|Mango': 'ಮಾವು',
    'Species|Rain Tree': 'ಮಳೆಮರ',
    'Species|Silver Oak': 'ಸಿಲ್ವರ್ ಓಕ್',
    'Species|Nilgiri': 'ನೀಲಗಿರಿ',
    'Species|Banyan': 'ಆಲ',
    'Species|Peepal': 'ಅರಳಿ',
    'Species|Tamarind': 'ಹುಣಸೆ',
    // Recommendation Type
    'Recommendation Type|Full Tree': 'ಪೂರ್ಣ ಮರ',
    'Recommendation Type|Branches Only': 'ಕೊಂಬೆಗಳು ಮಾತ್ರ',
    'Recommendation Type|Twigs Only': 'ಸಣ್ಣ ಕೊಂಬೆಗಳು ಮಾತ್ರ',
    'Recommendation Type|Top Portion Above 20 Feet':
        '20 ಅಡಿ ಮೇಲಿನ ತುದಿ ಭಾಗ',
    'Recommendation Type|Not Recommended':
        'ಶಿಫಾರಸು ಮಾಡಲಾಗಿಲ್ಲ',
    // Recommendation Reason
    'Recommendation Reason|Dead Tree': 'ಸತ್ತ ಮರ',
    'Recommendation Reason|Diseased Tree': 'ರೋಗಪೀಡಿತ ಮರ',
    'Recommendation Reason|Dangerous Tree': 'ಅಪಾಯಕಾರಿ ಮರ',
    'Recommendation Reason|Leaning Tree': 'ವಾಲಿದ ಮರ',
    'Recommendation Reason|Electric Line Clearance':
        'ವಿದ್ಯುತ್ ತಂತಿ ತೆರವು',
    'Recommendation Reason|Building Clearance': 'ಕಟ್ಟಡ ತೆರವು',
    'Recommendation Reason|Road Clearance': 'ರಸ್ತೆ ತೆರವು',
    'Recommendation Reason|Public Safety':
        'ಸಾರ್ವಜನಿಕ ಸುರಕ್ಷತೆ',
    'Recommendation Reason|Routine Pruning':
        'ನಿಯಮಿತ ಕತ್ತರಿಕೆ',
    'Recommendation Reason|Nursery Requirement':
        'ನರ್ಸರಿ ಅಗತ್ಯ',
    'Recommendation Reason|Dry Top': 'ಒಣಗಿದ ತುದಿ',
    'Recommendation Reason|Safety Clearance':
        'ಸುರಕ್ಷತಾ ತೆರವು',
    'Recommendation Reason|Healthy Tree': 'ಆರೋಗ್ಯಕರ ಮರ',
    'Recommendation Reason|Heritage Tree': 'ಪರಂಪರೆ ಮರ',
    'Recommendation Reason|Bird Nest Present':
        'ಹಕ್ಕಿ ಗೂಡು ಇದೆ',
    'Recommendation Reason|Religious Importance':
        'ಧಾರ್ಮಿಕ ಮಹತ್ವ',
    'Recommendation Reason|Others': 'ಇತರೆ',
    // Return Reason
    'Return Reason|Clarification Required':
        'ಸ್ಪಷ್ಟೀಕರಣ ಅಗತ್ಯ',
    'Return Reason|Documents Missing':
        'ದಾಖಲೆಗಳು ಲಭ್ಯವಿಲ್ಲ',
    // Inspection Deferred Reason
    'Inspection Deferred Reason|Applicant Not Available':
        'ಅರ್ಜಿದಾರರು ಲಭ್ಯವಿಲ್ಲ',
    'Inspection Deferred Reason|Site Not Traceable':
        'ಸ್ಥಳ ಪತ್ತೆಯಾಗಿಲ್ಲ',
    'Inspection Deferred Reason|Documents Not Available':
        'ದಾಖಲೆಗಳು ಲಭ್ಯವಿಲ್ಲ',
    'Inspection Deferred Reason|Wrong Location': 'ತಪ್ಪು ಸ್ಥಳ',
    'Inspection Deferred Reason|Tree Already Removed':
        'ಮರವನ್ನು ಈಗಾಗಲೇ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
    'Inspection Deferred Reason|Others': 'ಇತರೆ',
    // Standard Remark
    'Standard Remark|Inspection Completed':
        'ಪರಿಶೀಲನೆ ಪೂರ್ಣಗೊಂಡಿದೆ',
    'Standard Remark|Verified': 'ಪರಿಶೀಲಿಸಲಾಗಿದೆ',
    // Document Type
    'Document Type|RTC': 'ಆರ್‌ಟಿಸಿ',
    'Document Type|Survey Sketch': 'ಸರ್ವೆ ನಕ್ಷೆ',
    'Document Type|Aadhaar': 'ಆಧಾರ್',
    'Document Type|Revenue Certificate':
        'ಕಂದಾಯ ಪ್ರಮಾಣಪತ್ರ',
    'Document Type|Ownership Proof': 'ಮಾಲೀಕತ್ವ ಪುರಾವೆ',
    'Document Type|Court Order': 'ನ್ಯಾಯಾಲಯದ ಆದೇಶ',
    'Document Type|Other': 'ಇತರೆ',
    // Why Removing
    'Why Removing|Dangerous tree/branch':
        'ಅಪಾಯಕಾರಿ ಮರ/ಕೊಂಬೆ',
    'Why Removing|Self convenience': 'ಸ್ವಂತ ಅನುಕೂಲಕ್ಕಾಗಿ',
    'Why Removing|Development work': 'ಅಭಿವೃದ್ಧಿ ಕಾಮಗಾರಿ',
    'Why Removing|Financial benefit': 'ಆರ್ಥಿಕ ಲಾಭಕ್ಕಾಗಿ',
  };

  static String forEntry(String masterType, String value) =>
      names['$masterType|$value'] ?? '';
}

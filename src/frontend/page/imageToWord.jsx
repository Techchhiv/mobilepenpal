import React, { useState } from "react";
import MasterLayout from "../masterLayout/MasterLayout";
import API from "../../helper/api";

const ImageToWord = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(""); // To handle any error messages

  const handleFileChange = (e) => {
    setSelectedFile(e.target.files[0]);
    setError(""); // Reset error when file is selected
  };
  const handleConvert = async () => {
       if (!selectedFile) {
           alert("Please select an image file first.");
           return;
       }
   
       const formData = new FormData();
       formData.append("image", selectedFile);
   
       setLoading(true);
       setError(""); // Reset any previous error
   
       try {
           const response = await API.post("api/imagetoword", formData, {
               headers: {
                   "Content-Type": "multipart/form-data",
               },
           });
   
           // Assuming the response contains the file_url for download
           const fileUrl = response.data.file_url;
   
           // Trigger file download
           const link = document.createElement("a");
           link.href = fileUrl;
           link.setAttribute("download", "converted_with_image.docx");
           document.body.appendChild(link);
           link.click();
           link.remove();
       } catch (error) {
           console.error("Conversion failed:", error);
           setError(error.response?.data?.message || "Something went wrong during conversion.");
       } finally {
           setLoading(false);
       }
   };
   
  return (
    <MasterLayout>
      <div className="container mx-auto p-4 max-w-xl mt-10 bg-white rounded-lg shadow-md">
        <h2 className="text-2xl font-bold mb-2 text-center">🖼️ Image to Word</h2>
        <p className="text-gray-600 mb-4 text-center">
          Upload an image, and we’ll convert it into a Word document for you.
        </p>

        {/* File input */}
        <div className="mb-4">
          <input
            type="file"
            accept="image/*"
            onChange={handleFileChange}
            className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4
              file:rounded-full file:border-0 file:text-sm file:font-semibold
              file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
          />
        </div>

        {/* Display the selected file name */}
        {selectedFile && (
          <div className="mb-4 text-center text-green-600">
            ✅ File ready: {selectedFile.name}
          </div>
        )}

        {/* Show error message if any */}
        {error && (
          <div className="mb-4 text-center text-red-600">
            ❌ {error}
          </div>
        )}
         
        {/* Convert button */}
        <button
          onClick={handleConvert}
          disabled={loading}
          className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition"
        >
          {loading ? "Converting..." : "Convert to Word"}
        </button>
      </div>
    </MasterLayout>
  );
};

export default ImageToWord;

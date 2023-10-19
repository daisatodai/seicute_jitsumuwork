function browsePicture(button) {
  const file = $(button).siblings('.file-field')[0];
  const preview = $(button).siblings('.preview-field')[0];

  file.addEventListener('change', function () {
    if ( file.files[0] == 0 ) {
      alert('file not selected');
    } else {
      let fr = new FileReader();
      fr.onload = function () {
        preview.src = fr.result;
      }
      fr.readAsDataURL(file.files[0]);
    }
  });
  file.click();
}
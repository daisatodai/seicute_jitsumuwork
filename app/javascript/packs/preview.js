document.addEventListener('DOMContentLoaded', () => {
  const file_button = document.querySelector('#board_board_image');
  const preview_img = document.querySelector('#preview_img');

  file_button.addEventListener('change', (e) => {
    let file = e.target.files;
    let reader = new FileReader() ;
    reader.readAsDataURL(file[0])
    reader.onload = function() {
      preview_img.src = reader.result;
    }
    },false);
});
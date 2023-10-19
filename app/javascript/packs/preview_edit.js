$(document).on('turbolinks:load', function(){
  // 下記はedit用です。できれば別ファイルで作成することを推奨。バグの元
  var append_input = $(`<li class="input"><label class="upload-label"><div class="upload-label__text">ドラッグアンドドロップ<br>またはクリックしてファイルをアップロード<div class="input-area"><input class="hidden image_upload" type="file"></div></div></label></li>`)
  $ul = $('#previews')
  $lis = $ul.find('.image-preview');
  $input = $ul.find('.input');
  if($input.length == 0){
    if($lis.length <= 4 ){
      $ul.append(append_input)
      $('#previews .input').css({
        'width': `calc(100% - (20% * ${$lis.length}))`
      })
    }
    else if($lis.length == 5 ){
      $ul.append(append_input)
      $('#previews .input').css({
        'width': `100%`
      })
    }
    else if($lis.length <= 9 ){
      $ul.append(append_input)
      $('#previews .input').css({
        'width': `calc(100% - (20% * (${$lis.length} - 5 )))`
      })
    }
  }
});
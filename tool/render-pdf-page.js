ObjC.import('Quartz');
ObjC.import('AppKit');
ObjC.import('Foundation');
function run(argv) {
  var src = argv[0], pageIndex = parseInt(argv[1], 10), out = argv[2];
  var scale = argv[3] ? parseFloat(argv[3]) : 2.0;
  var url = $.NSURL.fileURLWithPath(src);
  var doc = $.PDFDocument.alloc.initWithURL(url);
  if (!doc.js) { return 'ERROR: could not open ' + src; }
  if (pageIndex >= doc.pageCount) {
    return 'ERROR: only ' + doc.pageCount + ' pages';
  }
  var page = doc.pageAtIndex(pageIndex);
  var img = page.thumbnailOfSizeForBox(
    $.NSMakeSize(page.boundsForBox(0).size.width * scale,
                 page.boundsForBox(0).size.height * scale), 0);
  var tiff = img.TIFFRepresentation;
  var rep = $.NSBitmapImageRep.imageRepWithData(tiff);
  var png = rep.representationUsingTypeProperties($.NSPNGFileType, $());
  png.writeToFileAtomically($(out), true);
  return 'OK ' + doc.pageCount + ' pages -> ' + out;
}

function [row,col]=getRowAndColumnInGrid(index,nRows,nCols)
row = nan;
col = nan;

if(index <= nRows*nCols)
  row = floor(index/nCols)+1;
  col = index - (row-1)*nCols;
  if(col==0)
    row=row-1;
    col=nCols;
  end
end
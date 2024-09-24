import * as fs from 'fs';
import { parse } from 'csv-parse';
import {check, check as decreaseCheck} from './decreasePositionCheck'
import {check as depositCheck} from './depositCheck'
import {check as withdrawCheck} from './withdrawCheck'
import {check as openPositionCheck} from './openPositionCheck'
import {check as liquidationCheck} from './liquidationCheck'

async function main() {
    const parser = fs
    .createReadStream(`./check/check_file/agdex.csv`)
    .pipe(parse({
        delimiter: ','
    }));
    let checkRes = [] as any[];
  for await (const element of parser) {
    // Work with each record
    console.log(element);
    if (element[2] == "open_position") {
        await openPositionCheck(element[1]).then((res)=>{element.push(res?.message); checkRes.push(element)}, (error)=>{console.error(error)});
    }
    else if (element[2] == "decrease_position") {
        await decreaseCheck(element[1]).then((res)=>{element.push(res?.message); checkRes.push(element)}, (error)=>{console.error(error)});
    }
    else if (element[2] == "liquidate_position") {
        await liquidationCheck(element[1]).then((res)=>{element.push(res?.message); checkRes.push(element)}, (error)=>{console.error(error)});
    }
    else if (element[2] == "deposit") {
        await depositCheck(element[1]).then((res)=>{element.push(res?.message); checkRes.push(element)}, (error)=>{console.error(error)});
    }
    else if (element[2] == "withdraw") {
        await withdrawCheck(element[1]).then((res)=>{element.push(res?.message); checkRes.push(element)}, (error)=>{console.error(error)});
    }
    else {
        console.log(element);
    }
  }
  await fs.promises.writeFile(`./check/check_file/input.csv`, 
  checkRes.join('\n'))
}

(async () => {
    await main();
})()